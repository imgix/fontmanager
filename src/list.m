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

#define PS_NAMES     (1<<0)
#define FAMILY_NAMES (1<<2)
#define PATHS        (1<<3)

static void usage (void);
static void config (FMConfig *cfg, int argc, char **argv);
static int run (const FMConfig *cfg);

const FMAction *const fm_list = &(const FMAction) {
	"list",
	"[-n] [-p] [-f]",
	"list the font names in the manager",
	usage, config, run
};

void
usage (void)
{
	fprintf (stderr,
		"%s options:\n"
		"    -p  list font paths (default)\n"
		"    -n  list PostScript names\n"
		"    -f  list font familty names\n"
		"\n"
		"    The -p and -n options may be combined to print out the\n"
		"    PostScript name and the font path. The -f option can only\n"
		"    be used by itself however.\n",
		fm_list->name
	);
}

void
config (FMConfig *cfg, int argc, char **argv)
{
	cfg->list_mode = 0;

	int c;
	while ((c = getopt (argc, argv, "nfp")) != -1) {
		switch (c) {
			case 'n':
				cfg->list_mode |= PS_NAMES;
				break;
			case 'f':
				cfg->list_mode |= FAMILY_NAMES;
				break;
			case 'p':
				cfg->list_mode |= PATHS;
				break;
			case '?':
				fm_usage_unknown (optopt);
				break;
		}
	}

	if (cfg->list_mode == 0) {
		cfg->list_mode = PATHS;
	}
}

int
run (const FMConfig *cfg)
{
	NSArray *names, *sorted;

	if (cfg->list_mode == FAMILY_NAMES) {
		names = (NSArray *)CTFontManagerCopyAvailableFontFamilyNames ();
		sorted = [names sortedArrayUsingSelector:@selector(localizedCompare:)];
		for (NSString *name in sorted) {
			if (![name hasPrefix:@"."]) {
				printf ("%s\n", [name cStringUsingEncoding:NSUTF8StringEncoding]);
			}
		}
		goto out;
	}

	names = (NSArray *)CTFontManagerCopyAvailableFontURLs ();
	sorted = [names sortedArrayUsingComparator:^ (NSURL *a, NSURL *b) {
		return [a.path compare:b.path];
	}];

	NSString *last = nil;
	for (NSURL *url in sorted) {
		// this currently assumes the fragment is postscript-name=value only
		NSString *ps = nil;
		if ([url.fragment hasPrefix:@"postscript-name="]) {
			ps = [url.fragment substringFromIndex:16];
			if ([ps hasPrefix:@"."]) {
				continue;
			}
		}

		if (!(cfg->list_mode & PS_NAMES) && [url.path isEqualToString:last]) {
			continue;
		}

		if (cfg->list_mode & PS_NAMES) {
			printf ("%s", [ps cStringUsingEncoding:NSUTF8StringEncoding]);
		}
		if (cfg->list_mode & PATHS) {
			if (cfg->list_mode & PS_NAMES) {
				printf (" ");
			}
			printf ("%s", [url.path cStringUsingEncoding:NSUTF8StringEncoding]);
		}
		printf ("\n");
		last = url.path;
	}
out:
	[names release];
	return 0;

}

