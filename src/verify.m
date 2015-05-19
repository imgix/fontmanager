//
//  verify.m
//  fontmanager
//
//  Created by Jeremy Larkin on 5/19/15.
//  Copyright (c) 2015 Imgix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

#include "verify.h"

static void usage (void);
static void config (FMConfig *cfg, int argc, char **argv);
static int run (const FMConfig *cfg);

const FMAction *const fm_verify = &(const FMAction) {
	"verify",
	"[-s SCOPE] FILE ...",
	"determine whether a font is supported on the current platform",
	usage, config, run
};

void
usage (void)
{
	// no usage
}

void
config (FMConfig *cfg, int argc, char **argv)
{
	cfg->files = fm_file_urls (argv + optind, argc - optind);
}

int
run (const FMConfig *cfg)
{
	int rc = 0;
	for (NSURL *url in (NSArray *)cfg->files) {
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
