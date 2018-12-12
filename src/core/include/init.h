#ifndef _INIT_H_
#define _INIT_H_

extern void __fastcall__ init_set_nmi_handler(void (*f)(void));
extern void __fastcall__ nmi_handler(void);

#endif
