#ifndef COMMANDER_DEBUG_H
#define COMMANDER_DEBUG_H

#include <Commander/global.h>

#include <QtCore/qloggingcategory.h>

#define commanderDebug()    qCDebug(commander)
#define commanderInfo()     qCInfo(commander)
#define commanderWarning()  qCWarning(commander)
#define commanderCritical() qCritical(commander)
#define commanderFatal()    qCFatal(commander)

#ifdef QT_DEBUG
#   define COMMANDER_DEBUG
#   define COMMANDER_INFO
#   define COMMANDER_WARNING
#   define COMMANDER_CRITICAL
#   define COMMANDER_FATAL
#endif

COMMANDER_EXPORT Q_DECLARE_LOGGING_CATEGORY(commander)

#endif // COMMANDER_DEBUG_H
