//
//  main.m
//  fontmanager
//
//  Created by Jeremy Larkin on 5/18/15.
//  Copyright (c) 2015 Imgix. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>



typedef struct Config Config;
typedef struct Action Action;

#define LIST_GROUP 0
#define LIST_PS_NAMES 1
#define LIST_FAMILY_NAMES 2
#define LIST_PATHS 3

struct Config {
	const Action *action;
	NSArray *files;
	CTFontManagerScope scope;
	int list;
	bool verbose;
};

struct Action {
	const char *name;
	void (*config)(Config *cfg, int argc, char **argv);
	int (*run)(Config *cfg);
};

static void config_register (Config *cfg, int argc, char **argv);
static void config_list (Config *cfg, int argc, char **argv);
static void config_verify (Config *cfg, int argc, char **argv);
static int run_register (Config *cfg);
static int run_unregister (Config *cfg);
static int run_list (Config *cfg);
static int run_verify (Config *cfg);

static const Action actions[] = {
	{ "register", config_register, run_register },
	{ "unregister", config_register, run_unregister },
	{ "list", config_list, run_list },
	{ "verify", config_verify, run_verify },
	{ NULL, NULL }
};


static void
usage (int rc)
{
	fprintf (stderr,
		"usage: fontmanager [-v] register [-s SCOPE] FILE ...\n"
		"       fontmanager [-v] unregister [-s SCOPE] FILE ...\n"
		"       fontmanager [-v] verify FILE ...\n"
		"       fontmanager list\n"
		"\n"
		"global options:\n"
		"    -v  enable verbose mode\n"
		"    -h  show help and exit\n"
		"\n"
		"subcommands:\n"
		"    register: add fonts to the font manager\n"
		"    unregister: remove fonts from the font manager\n"
		"    verify: determine whether a font is supported on the current platform\n"
		"    list: list the font names in the manager\n"
		"\n"
		"register options:\n"
		"    -s  scope for the operation, user (default) or session\n"
		"\n"
		"unregister options:\n"
		"    -s  scope for the operation, user (default) or session\n"
		"\n"
		"list options:\n"
		"    -n  list PostScript names (default)\n"
		"    -f  list font familty names\n"
		"    -p  list font paths\n"
		"\n"
	);
	exit (rc);
}

static void
print_unkown (void)
{
	if (isprint (optopt)) {
		fprintf (stderr, "Unknown option '-%c'.\n", optopt);
	}
	else {
		fprintf (stderr, "Unknown option character '\\x%x'.\n", optopt);
	}
	usage (1);
}

static NSArray *
create_urls (char **urls, int len)
{
	NSMutableArray *files = [NSMutableArray arrayWithCapacity:len];
	for (int i = 0; i < len; i++) {
		NSString *filePath = [NSString stringWithCString:urls[i] encoding:NSUTF8StringEncoding];
		NSURL *fileURL = [[NSURL fileURLWithPath:filePath] URLByStandardizingPath];
		[files addObject:fileURL];
	}
	return files;
}

static void
config_register (Config *cfg, int argc, char **argv)
{
	cfg->scope = kCTFontManagerScopeUser;
	cfg->files = nil;
	
	int c;
	while ((c = getopt (argc, argv, "s:")) != -1) {
		switch (c) {
			case 's':
				if (strcasecmp ("user", optarg) == 0) {
					cfg->scope = kCTFontManagerScopeUser;
				}
				else if (strcasecmp ("session", optarg) == 0) {
					cfg->scope = kCTFontManagerScopeSession;
				}
				else {
					fprintf (stderr, "Unknown scope '%s'.\n", optarg);
					usage (1);
				}
				break;
			case '?':
				print_unkown ();
				break;
		}
	}
	
	cfg->files = create_urls (argv + optind, argc - optind);
}

static void
config_list (Config *cfg, int argc, char **argv)
{
	cfg->list = LIST_PS_NAMES;

	int c;
	while ((c = getopt (argc, argv, "nfp")) != -1) {
		switch (c) {
			case 'n':
				cfg->list = LIST_PS_NAMES;
				break;
			case 'f':
				cfg->list = LIST_FAMILY_NAMES;
				break;
			case 'p':
				cfg->list = LIST_PATHS;
				break;
			case '?':
				print_unkown ();
				break;
		}
	}
}

static void
config_verify (Config *cfg, int argc, char **argv)
{
	cfg->files = create_urls (argv + optind, argc - optind);
}

static void
parse_config (Config *cfg, int argc, char **argv)
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
				usage (0);
				break;
			case '?':
				print_unkown ();
				break;
		}
	}
	
	if (optind >= argc) {
		fprintf (stderr, "Subcommand not specified.\n");
		usage (1);
	}
	
	for (int i = 0; actions[i].name != NULL; i++) {
		if (strcasecmp (actions[i].name, argv[optind]) == 0) {
			cfg->action = &actions[i];
			break;
		}
	}

	if (cfg->action == NULL) {
		fprintf (stderr, "Unkown subcommand '%s'.\n", argv[optind]);
		usage (1);
	}
	if (cfg->action != NULL) {
		int off = optind + 1;
		optind = 0;
		cfg->action->config (cfg, argc - off, argv + off);
	}
}


static int
proc_fonts (Config *cfg, bool (^proc)(CFArrayRef, CFArrayRef *))
{
	CFArrayRef errors = NULL;
	int rc = 0;
	NSUInteger failed = 0;
	NSUInteger total = cfg->files.count;
	
	if (proc ((CFArrayRef)cfg->files, &errors)) {
		goto out;
	}
	
	for (NSError *err in (NSArray *)errors) {
		NSArray *files = [err.userInfo valueForKey:(NSString *)kCTFontManagerErrorFontURLsKey];
		bool warn = err.code == 105 || err.code == 201;
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
	
out:
	printf ("[%s:%s] %lu of %lu files processed.\n",
			rc == 0 ? "OK" : "FAIL",
			cfg->action->name,
			total - failed,
			total);
	return rc;
}

static int
run_register (Config *cfg)
{
	return proc_fonts(cfg, ^(CFArrayRef files, CFArrayRef *err) {
		return CTFontManagerRegisterFontsForURLs (files, cfg->scope, err);
	});
}

static int
run_unregister (Config *cfg)
{
	return proc_fonts(cfg, ^(CFArrayRef files, CFArrayRef *err) {
		return CTFontManagerUnregisterFontsForURLs (files, cfg->scope, err);
	});
}

static int
run_list (Config *cfg)
{
	NSArray *names, *sorted;
	NSString *last = nil;

	switch (cfg->list) {

		case LIST_FAMILY_NAMES:
			names = (NSArray *)CTFontManagerCopyAvailableFontFamilyNames ();
			break;

		case LIST_PS_NAMES:
		default:
			names = (NSArray *)CTFontManagerCopyAvailablePostScriptNames ();
			break;

		case LIST_PATHS:
			names = (NSArray *)CTFontManagerCopyAvailableFontURLs ();
			sorted = [names sortedArrayUsingComparator:^ (NSURL *a, NSURL *b) {
				return [a.path compare:b.path];
			}];
			for (NSURL *url in sorted) {
				if ([url.path isEqualToString:last]) {
					continue;
				}
				last = url.path;
				printf ("%s\n", [last cStringUsingEncoding:NSUTF8StringEncoding]);
			}
			goto out;

	}
	for (NSString *name in names) {
		if (![name hasPrefix:@"."]) {
			printf ("%s\n", [name cStringUsingEncoding:NSUTF8StringEncoding]);
		}
	}
out:
	[names release];
	return 0;
}

static int
run_verify (Config *cfg)
{
	int rc = 0;
	for (NSURL *url in cfg->files) {
		bool ok = CTFontManagerIsSupportedFont ((CFURLRef)url);
		if (cfg->verbose) {
			printf ("[%s:%s] %s\n",
					ok ? "OK" : "FAIL",
					cfg->action->name,
					[[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
		}
		if (!ok) {
			rc = 1;
			if (!cfg->verbose) {
				break;
			}
		}
	}
	return rc;
}


int
main(int argc, char **argv)
{
	int rc;
	@autoreleasepool {
		Config cfg;
		parse_config (&cfg, argc, argv);
		rc = cfg.action->run (&cfg);
	}
    return rc;
}
