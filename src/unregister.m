//
//  unregister.m
//  fontmanager
//
//  Created by Jeremy Larkin on 5/19/15.
//  Copyright (c) 2015 Imgix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

#include "unregister.h"

static void usage (void);
static void config (FMConfig *cfg, int argc, char **argv);
static int run (const FMConfig *cfg);

const FMAction *const fm_unregister = &(const FMAction) {
	"unregister",
	"remove fonts to the font manager",
	usage, config, run
};

void
usage (void)
{
	fprintf (stderr,
		"%s options:\n"
		"    -s  scope for the operation, user (default) or session\n",
		fm_register->name
	);
}

void
config (FMConfig *cfg, int argc, char **argv)
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
					fm_usage (1);
				}
				break;
			case '?':
				fm_usage_unknown (optopt);
				break;
		}
	}
	
	cfg->files = fm_file_urls (argv + optind, argc - optind);
}

int
run (const FMConfig *cfg)
{
	CFArrayRef errors = NULL;
	CFIndex total = CFArrayGetCount (cfg->files);
	
	CTFontManagerUnregisterFontsForURLs (cfg->files, cfg->scope, &errors);
	return fm_check_errors(cfg, errors, kCTFontManagerErrorNotRegistered, total);
}
