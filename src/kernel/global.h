#ifndef COMMANDER_GLOBAL_H
#define COMMANDER_GLOBAL_H

#include <Commander/config.h>

#ifdef COMMANDER_SHARED
#   ifdef BUILD_COMMANDER_LIB
#       define COMMANDER_EXPORT Q_DECL_EXPORT
#   else
#       define COMMANDER_EXPORT Q_DECL_IMPORT
#   endif
#else
#    define COMMANDER_EXPORT
#endif

#define COMMANDER_DECLARE_PRIVATE(Class) friend class Class##Private;
#define COMMANDER_DECLARE_PUBLIC(Class) friend class Class;

#define COMMANDER_D(Class) Class##Private *d = static_cast<Class##Private *>(qGetPtrHelper(this->d));
#define COMMANDER_Q(Class) Class *q = static_cast<Class *>(this->q);

#endif // COMMANDER_GLOBAL_H
