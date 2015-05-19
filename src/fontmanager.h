//
//  main.h
//  fontmanager
//
//  Created by Jeremy Larkin on 5/19/15.
//  Copyright (c) 2015 Imgix. All rights reserved.
//

#ifndef fontmanager_h
#define fontmanager_h

#import <CoreFoundation/CoreFoundation.h>
#import <CoreText/CoreText.h>

typedef struct FMConfig FMConfig;
typedef struct FMAction FMAction;

struct FMAction {
	const char *name, *args, *about;
	void (*usage)(void);
	void (*config)(FMConfig *cfg, int argc, char **argv);
	int (*run)(const FMConfig *cfg);
};

#include "register.h"
#include "unregister.h"
#include "list.h"
#include "verify.h"

struct FMConfig {
	const FMAction *action;
	bool verbose;
	CFArrayRef files;
	CTFontManagerScope scope;
	int list_mode;
};

extern void
fm_usage (int rc);

extern void
fm_usage_unknown (int ch);

extern CFArrayRef
fm_file_urls (char **urls, int n);

extern int
fm_check_errors (const FMConfig *cfg, CFArrayRef errors, CFIndex warn_code, CFIndex total);

#endif
