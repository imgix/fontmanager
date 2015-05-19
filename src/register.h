//
//  register.h
//  fontmanager
//
//  Created by Jeremy Larkin on 5/19/15.
//  Copyright (c) 2015 Imgix. All rights reserved.
//

#ifndef fontmanager_register_h
#define fontmanager_register_h

#include "fontmanager.h"

extern const FMAction *const fm_register;

typedef struct {
	CFArrayRef files;
	CTFontManagerScope scope;
} FMConfigRegister;

#endif
