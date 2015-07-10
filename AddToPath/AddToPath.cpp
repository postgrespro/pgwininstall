/* AddToPath plugin for NSIS
 * Add and remove record from PATH environment variable
 * Copyright (C) 2015 Victor Spirin <vvs13@mail.ru>
 * some defintions I took from AccessControl plugin by Mathias Hasselmann
 */
#define WIN32_LEAN_AND_MEAN
#ifdef _WIN64
#define WINVER 0x502
#else
#define WINVER 0x400
#endif

#include <windows.h>
#ifdef UNICODE
#include "nsis_unicode/pluginapi.h"
#else
#include "nsis_ansi/pluginapi.h"
#endif
#include <aclapi.h>
#include <sddl.h>
//#include <tchar.h>

/*****************************************************************************
 GLOBAL VARIABLES
 *****************************************************************************/

HINSTANCE g_hInstance = NULL;
int g_string_size = 1024;
extra_parameters* g_extra = NULL;

/*****************************************************************************
 UTILITIES
 *****************************************************************************/

#define SIZE_OF_ARRAY(Array) (sizeof((Array)) / sizeof(*(Array)))
#define ARRAY_CONTAINS(Array, Index) (Index >= 0 && Index < SIZE_OF_ARRAY(Array))

void* LocalAllocZero(size_t cb) { return LocalAlloc(LPTR, cb); }
inline void* LocalAlloc(size_t cb) { return LocalAllocZero(cb); }

/*****************************************************************************
 PLUG-IN HANDLING
 *****************************************************************************/

#define PUBLIC_FUNCTION(Name) \
extern "C" void __declspec(dllexport) __cdecl Name(HWND hWndParent, int string_size, TCHAR* variables, stack_t** stacktop, extra_parameters* extra) \
{ \
  EXDLL_INIT(); \
  g_string_size = string_size; \
  g_extra = extra;

#define PUBLIC_FUNCTION_END \
}


//only for test
bool getPath(TCHAR *buf, DWORD* buflen)
{
	HKEY phk;
	LONG ret;
	
	ret=RegOpenKeyEx(HKEY_LOCAL_MACHINE,TEXT("SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"),0,
	KEY_READ,	// security access mask :KEY_ALL_ACCESS
	&phk 	// address of handle of open key
 );
 if(ret!=ERROR_SUCCESS){
	 
	wsprintf(buf, TEXT("Error 1. Error code: %d"), ret);
	 return false;
 }
 
 DWORD dw;
 dw=REG_EXPAND_SZ;
 //DWORD tmp=len;

 TCHAR *str= (TCHAR*)LocalAlloc(8001*sizeof(TCHAR));
 
 DWORD n;
 n=8000;
 ret=RegQueryValueEx(
		phk,	// handle of key to query
		TEXT("Path"),	// address of name of value to query
		NULL,	// reserved
	   &dw,//REG_DWORD,	// address of buffer for value type
	   //(BYTE *)buf,	// address of value data
	 //(LPDWORD)buflen	// size of value data
	   (BYTE *)str,	// address of value data
	 (LPDWORD)&n	// size of value data

   );

 if(ret!=ERROR_SUCCESS){
 	*buf=0;
	RegCloseKey(phk);
	wsprintf(buf, TEXT("Error 2. Error code: %d"), ret);
	LocalFree(str);
	return false;
 }
 
 lstrcpyn(buf,str,*buflen);
 LocalFree(str);
 RegCloseKey(phk);
 return true;
}

//for test
PUBLIC_FUNCTION(GetPathString)
{
  TCHAR *name = (TCHAR*)LocalAlloc(string_size*sizeof(TCHAR)), *retstr = TEXT("error");
  DWORD dwName = string_size;
  //if (name && getPath(name, &dwName)) retstr = name;
  if (name && getPath(name, &dwName)) retstr = name;
  pushstring(retstr);
  LocalFree(name);
}
PUBLIC_FUNCTION_END



char *_strstr(char *i, const char *s)
{
  if (lstrlen(i)>=lstrlen(s)) while (i[lstrlen(s)-1])
  {
    int l=lstrlen(s)+1;
    char *ii=i;
    const char *is=s;
    while (--l>0)
    {
		
      if (*ii != *is) break;
      ii++;
      is++;
    }
    if (l==0) return i;
    i++;
  }
  return NULL;
}





bool ChangePath(TCHAR *path, bool isAdd,bool allUser)
{
	HKEY phk;
	LONG ret;
	if(lstrlen(path)>256) return false;
	if(allUser){
		ret=RegOpenKeyEx(HKEY_LOCAL_MACHINE,
			TEXT("SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment"),
			0,
			KEY_ALL_ACCESS,	// security access mask :KEY_ALL_ACCESS
			&phk 	// address of handle of open key
			);
	}
	else{
		ret=RegOpenKeyEx(HKEY_CURRENT_USER,
			TEXT("Environment"),
			0,
			KEY_READ,	// security access mask :KEY_ALL_ACCESS
			&phk 	// address of handle of open key
			);
	}

	if(ret!=ERROR_SUCCESS){
		return false;
	}
 
	DWORD dw;
	dw=REG_EXPAND_SZ;
	TCHAR *str= (TCHAR*)LocalAlloc(8500*sizeof(TCHAR));
	DWORD n=8192;
	
	ret=RegQueryValueEx(
		phk,	// handle of key to query
		TEXT("Path"),	// address of name of value to query
		NULL,	// reserved
	   &dw,//REG_DWORD,	// address of buffer for value type
	   //(BYTE *)buf,	// address of value data
	 //(LPDWORD)buflen	// size of value data
	   (BYTE *)str,	// address of value data
	 (LPDWORD)&n	// size of value data
   );

 if(ret!=ERROR_SUCCESS || str[0] == 0){
	RegCloseKey(phk);
	LocalFree(str);
	return false;
 }
 //find path
 //TCHAR *p = _tcsstr(str,path);

	TCHAR *p = _strstr(str,path);
	//MessageBox(0,str,path,MB_OK);

 if(p!=NULL){//exist
	 //MessageBox(0,p,"NOT NULL",MB_OK);
	 if(isAdd){
		 LocalFree(str);
		 RegCloseKey(phk);
		 return true;
	 }
	 //remove
	 //TCHAR *tmp=(TCHAR*)LocalAlloc(8500*sizeof(TCHAR));
	 //if(tmp){
	 *p=0;
	 if(p!=str && (*(p-1)==';')) *(p-1)=0;
	 lstrcat(str,p+lstrlen(path));

 }
 else{
	 //MessageBox(0,"NULL","",MB_OK);
	 if(!isAdd){
		 LocalFree(str);
		 RegCloseKey(phk);
		 return true;
	 }
	 int l=lstrlen(str);
	 if(l>0 && str[l-1]!=';') lstrcat(str,";");
	 lstrcat(str,path);

	 //}

 }
 //MessageBox(0,str,"",MB_OK);
 
 ret=RegSetValueEx(phk,	// handle of key to set value for
			TEXT("Path"),// address of value to set
				0,	// reserved
   	 		REG_EXPAND_SZ,	// flag for value type
	    		(BYTE *)str,	// address of value data
   	 		lstrlen(str)+1 	// size of value data
 );
 if(ret!=ERROR_SUCCESS){
		 LocalFree(str);
		 RegCloseKey(phk);
		return false;
 }

 //SendMessage(HWND_BROADCAST, WM_SETTINGCHANGE, 0, (LPARAM)"Environment");

 DWORD dwReturnValue;

 SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0,
	 (LPARAM) "Environment", SMTO_ABORTIFHUNG,
	 2000, &dwReturnValue);


 LocalFree(str);
 RegCloseKey(phk);
 return true;
}



PUBLIC_FUNCTION(AddToPath)
{
	TCHAR *retstr = TEXT("error");
	TCHAR* param = (TCHAR*)LocalAlloc(g_string_size*sizeof(TCHAR));
	popstring(param);
	if(param && ChangePath(param, true,true)) retstr = TEXT("ok");
	LocalFree(param);
	pushstring(retstr);

}
PUBLIC_FUNCTION_END

PUBLIC_FUNCTION(RemoveFromPath)
{
	TCHAR *retstr = TEXT("error");
	TCHAR* param = (TCHAR*)LocalAlloc(g_string_size*sizeof(TCHAR));
	popstring(param);
	if(param && ChangePath(param, false,true)) retstr = TEXT("ok");
	LocalFree(param);
	pushstring(retstr);

}
PUBLIC_FUNCTION_END

PUBLIC_FUNCTION(TestPath)
{
	TCHAR *retstr = TEXT("error");
	TCHAR* param = (TCHAR*)LocalAlloc(g_string_size*sizeof(TCHAR));
	popstring(param);
	TCHAR* param2 = (TCHAR*)LocalAlloc(g_string_size*sizeof(TCHAR));
	popstring(param2);

	MessageBox(0,param,param2,MB_OK);
	
	LocalFree(param2);
	LocalFree(param);
	pushstring(retstr);

}
PUBLIC_FUNCTION_END

PUBLIC_FUNCTION(SetEnvVar)
{
	TCHAR *retstr = TEXT("error");
	TCHAR* param = (TCHAR*)LocalAlloc(g_string_size*sizeof(TCHAR));
	if(popstring(param)){
		LocalFree(param);
		pushstring(retstr);
		return;
	}
	TCHAR* param2 = (TCHAR*)LocalAlloc(g_string_size*sizeof(TCHAR));
	if(popstring(param2)){
		LocalFree(param2);
		LocalFree(param);
		pushstring(retstr);
		return;
	}

	
	
	LocalFree(param2);
	LocalFree(param);
	pushstring(retstr);

}
PUBLIC_FUNCTION_END


#ifdef _VC_NODEFAULTLIB
#define DllMain _DllMainCRTStartup
#endif
EXTERN_C BOOL WINAPI DllMain(HINSTANCE hInst, ULONG ul_reason_for_call, LPVOID lpReserved)
{
  g_hInstance = (HINSTANCE)hInst;
  return TRUE;
}