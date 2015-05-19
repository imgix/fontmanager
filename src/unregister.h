//
//  unregister.h
//  fontmanager
//
//  Created by Jeremy Larkin on 5/19/15.
//  Copyright (c) 2015 Imgix. All rights reserved.
//

#ifndef fontmanager_unregister_h
#define fontmanager_unregister_h

#include "fontmanager.h"

extern const FMAction *const fm_unregister;

typedef struct {
	CFArrayRef files;
	CTFontManagerScope scope;
} FMConfigUnregister;

#endif
