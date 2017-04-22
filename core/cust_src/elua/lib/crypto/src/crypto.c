/**************************************************************************
 *              Copyright (C), AirM2M Tech. Co., Ltd.
 *
 * Name:   crypto.c
 * Author:  zhutianhua
 * Date:    2017/4/17
 *
 * Description:
 *          lua.crypto¿â
 **************************************************************************/
#include "crypto.h"


static int l_crypto_base64_encode(lua_State *L)
{
    const char *inputData = luaL_checkstring(L,1);
    int inputLen = luaL_checkinteger(L, 2);
    u8 *outputData = NULL;
    u32 outputLen = 0;
    u32 outputLenMax = (inputLen/3+1)*4;

    luaL_Buffer b;
    luaL_buffinit( L, &b );
    
    if(outputLenMax > LUAL_BUFFERSIZE)
    {
        outputData = malloc(outputLenMax+1);
        memset(outputData,0,outputLenMax+1);
        aliyun_iot_common_base64encode(inputData, inputLen, outputLenMax, outputData, &outputLen);
        luaL_addlstring(&b,outputData,outputLen);
        free(outputData);
        outputData = NULL;
    }
    else
    {
        aliyun_iot_common_base64encode(inputData, inputLen, LUAL_BUFFERSIZE, b.p, &outputLen);
        b.p += outputLen;
    }
    
    luaL_pushresult( &b );
    return 1;
}


static int l_crypto_base64_decode(lua_State *L)
{
    const char *inputData = luaL_checkstring(L,1);
    int inputLen = luaL_checkinteger(L, 2);
    u8 *outputData = NULL;
    u32 outputLen = 0;
    u32 outputLenMax = inputLen*3/4+1;

    luaL_Buffer b;
    luaL_buffinit( L, &b );
    
    if(outputLenMax > LUAL_BUFFERSIZE)
    {
        outputData = malloc(outputLenMax+1);
        memset(outputData,0,outputLenMax+1);
        aliyun_iot_common_base64decode(inputData, inputLen, outputLenMax, outputData, &outputLen);
        luaL_addlstring(&b,outputData,outputLen);
        free(outputData);
        outputData = NULL;
    }
    else
    {
        aliyun_iot_common_base64decode(inputData, inputLen, LUAL_BUFFERSIZE, b.p, &outputLen);
        b.p += outputLen;
    }
    
    luaL_pushresult( &b );
    return 1;
}


static int l_crypto_hmac_md5(lua_State *L)
{
    const char *inputData = luaL_checkstring(L,1);
    int inputLen = luaL_checkinteger(L, 2);
    const char *signKey = luaL_checkstring(L,3);
    int signKeyLen = luaL_checkinteger(L, 4);    

    luaL_Buffer b;
    luaL_buffinit( L, &b );    

    memset(b.buffer,0,LUAL_BUFFERSIZE);
    aliyun_iot_common_hmac_md5(inputData, inputLen, b.p, signKey, signKeyLen);
    b.p += strlen(b.buffer);
    
    luaL_pushresult( &b );
    return 1;
}


static int l_crypto_md5(lua_State *L)
{
    const char *inputData = luaL_checkstring(L,1);
    int inputLen = luaL_checkinteger(L, 2);

    luaL_Buffer b;
    luaL_buffinit( L, &b );    

    memset(b.buffer,0,LUAL_BUFFERSIZE);
    aliyun_iot_common_md5(inputData, inputLen, b.p);
    b.p += strlen(b.buffer);
    
    luaL_pushresult( &b );
    return 1;
}



#define MIN_OPT_LEVEL 2
#include "lrodefs.h"
const LUA_REG_TYPE crypto_map[] =
{
    { LSTRKEY( "base64_encode" ),  LFUNCVAL( l_crypto_base64_encode ) },
    { LSTRKEY( "base64_decode" ),  LFUNCVAL( l_crypto_base64_decode ) },
    { LSTRKEY( "hmac_md5" ),  LFUNCVAL( l_crypto_hmac_md5 ) },
    { LSTRKEY( "md5" ),  LFUNCVAL( l_crypto_md5 ) },

    { LNILKEY, LNILVAL }
};

int luaopen_crypto( lua_State *L )
{
    luaL_register( L, AUXLIB_CRYPTO, crypto_map );
    return 1;
}

