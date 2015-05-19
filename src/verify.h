//
//  verify.h
//  fontmanager
//
//  Created by Jeremy Larkin on 5/19/15.
//  Copyright (c) 2015 Imgix. All rights reserved.
//

#ifndef fontmanager_verify_h
#define fontmanager_verify_h

#include "fontmanager.h"

extern const FMAction *const fm_verify;

typedef struct {
	CFArrayRef files;
} FMConfigVerify;

#endif
