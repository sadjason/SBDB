//
//  ConfigWrapper.h
//  SQLite
//
//  Created by zhangwei on 2019/10/30.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#ifndef Config_Wrapper_h
#define Config_Wrapper_h

#include <sqlite3.h>

int sqlite_config_wrapper(int value) {
    return sqlite3_config(value);
}

#endif /* Config_h */
