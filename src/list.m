//
//  list.m
//  fontmanager
//
//  Created by Jeremy Larkin on 5/19/15.
//  Copyright (c) 2015 Imgix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

#include "list.h"

#define PS_NAMES 1
#define FAMILY_NAMES 2
#define PATHS 3

static void usage (void);
static void config (FMConfig *cfg, int argc, char **argv);
static int run (const FMConfig *cfg);

const FMAction *const fm_list = &(const FMAction) {
	"list",
	"list the font names in the manager",
	usage, config, run
};

void
usage (void)
{
	fprintf (stderr,
		"%s options:\n"
		"    -n  list PostScript names (default)\n"
		"    -f  list font familty names\n"
		"    -p  list font paths\n",
		fm_list->name
	);
}

void
config (FMConfig *cfg, int argc, char **argv)
{
	cfg->list_mode = PS_NAMES;

	int c;
	while ((c = getopt (argc, argv, "nfp")) != -1) {
		switch (c) {
			case 'n':
				cfg->list_mode = PS_NAMES;
				break;
			case 'f':
				cfg->list_mode = FAMILY_NAMES;
				break;
			case 'p':
				cfg->list_mode = PATHS;
				break;
			case '?':
				fm_usage_unknown (optopt);
				break;
		}
	}
}

int
run (const FMConfig *cfg)
{
	NSArray *names, *sorted;
	NSString *last = nil;

	switch (cfg->list_mode) {

		case FAMILY_NAMES:
			names = (NSArray *)CTFontManagerCopyAvailableFontFamilyNames ();
			break;

		case PS_NAMES:
		default:
			names = (NSArray *)CTFontManagerCopyAvailablePostScriptNames ();
			break;

		case PATHS:
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

