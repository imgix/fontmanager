//
//  main.m
//  fontmanager
//
//  Created by Jeremy Larkin on 5/18/15.
//  Copyright (c) 2015 Imgix. All rights reserved.
//

#include "fontmanager.h"

#import <Foundation/Foundation.h>

static const FMAction *const *actions;

void
fm_usage (int rc)
{
	fprintf (stderr, "usage: ");
	for (int i = 0; actions[i] != NULL; i++) {
		if (i > 0) {
			fprintf (stderr, "       ");
		}
		fprintf (stderr, "fontmanager [-v] %s %s\n", actions[i]->name, actions[i]->args);
	}
	fprintf (stderr,
		"\n"
		"global options:\n"
		"    -v  enable verbose mode\n"
		"    -h  show help and exit\n"
		"\n"
		"subcommands:\n"
	);
	for (int i = 0; actions[i] != NULL; i++) {
		fprintf (stderr, "    %s: %s\n", actions[i]->name, actions[i]->about);
	}
	fprintf (stderr, "\n");
	for (int i = 0; actions[i] != NULL; i++) {
		actions[i]->usage ();
		fprintf (stderr, "\n");
	}
	exit (rc);
}

void
fm_usage_unknown (int ch)
{
	if (isprint (ch)) {
		fprintf (stderr, "Unknown option '-%c'.\n", ch);
	}
	else {
		fprintf (stderr, "Unknown option character '\\x%x'.\n", ch);
	}
	fm_usage (1);
}

CFArrayRef
fm_file_urls (char **urls, int n)
{
	char buf[4096];
	NSURL *base = [NSURL fileURLWithPath:[NSString stringWithUTF8String:getcwd (buf, sizeof buf)]];
	NSMutableArray *files = [NSMutableArray arrayWithCapacity:n];
	for (int i = 0; i < n; i++) {
		NSString *filePath = [NSString stringWithCString:urls[i] encoding:NSUTF8StringEncoding];
		NSURL *fileURL = [NSURL URLWithString:[filePath stringByExpandingTildeInPath] relativeToURL:base];
		[files addObject:fileURL];
	}
	return (CFArrayRef)files;
}

int
fm_check_errors (const FMConfig *cfg, CFArrayRef errors, CFIndex warn_code, CFIndex total)
{
	CFIndex failed = 0;
	int rc = 0;
	if (errors != NULL) {
		for (NSError *err in (NSArray *)errors) {
			NSArray *files = [err.userInfo valueForKey:(NSString *)kCTFontManagerErrorFontURLsKey];
			bool warn = err.code == warn_code;
			if (!warn || (warn && cfg->verbose)) {
				printf ("[%s:%s] %s (%lu)\n",
						warn ? "WARN" : "FAIL",
						cfg->action->name,
						[err.localizedDescription cStringUsingEncoding:NSUTF8StringEncoding],
						err.code);
				for (NSURL *file in files) {
					printf ("    %s\n",
							[[file path] cStringUsingEncoding:NSUTF8StringEncoding]);
				}
			}
			if (!warn) {
				rc = 1;
				failed += files.count;
			}
		}
	}
	
out:
	printf ("[%s:%s] %lu of %lu files processed.\n",
			rc == 0 ? "OK" : "FAIL",
			cfg->action->name,
			total - failed,
			total);
	return rc;
}

static void
parse_config (FMConfig *cfg, int argc, char **argv)
{
	cfg->action = NULL;
	cfg->verbose = false;
	
	int c;
	while ((c = getopt (argc, argv, "vh")) != -1) {
		switch (c) {
			case 'v':
				cfg->verbose = 1;
				break;
			case 'h':
				fm_usage (0);
				break;
			case '?':
				fm_usage_unknown (optopt);
				break;
		}
	}
	
	if (optind >= argc) {
		fprintf (stderr, "Subcommand not specified.\n");
		fm_usage (1);
	}
	
	for (int i = 0; actions[i]->name != NULL; i++) {
		if (strcasecmp (actions[i]->name, argv[optind]) == 0) {
			cfg->action = actions[i];
			break;
		}
	}

	if (cfg->action == NULL) {
		fprintf (stderr, "Unkown subcommand '%s'.\n", argv[optind]);
		fm_usage (1);
	}
	if (cfg->action != NULL) {
		int off = optind + 1;
		optind = 0;
		cfg->action->config (cfg, argc - off, argv + off);
	}
}

int
main (int argc, char **argv)
{
	actions = (const FMAction *[]){
		fm_register,
		fm_unregister,
		fm_list,
		fm_verify,
		NULL
	};
	
	FMConfig cfg;
	memset (&cfg, 0, sizeof cfg);
	
	int rc;
	@autoreleasepool {
		parse_config (&cfg, argc, argv);
		rc = cfg.action->run (&cfg);
	}
    return rc;
}

