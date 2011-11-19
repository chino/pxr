#ifndef DEBUG_DRAWER
#define DEBUG_DRAWER

#include <bullet/LinearMath/btIDebugDraw.h>

/*
enum DebugDrawModes {
  DBG_NoDebug = 0,
  DBG_DrawWireframe = 1,
  DBG_DrawAabb = 2,
  DBG_DrawFeaturesText = 4,
  DBG_DrawContactPoints = 8,
  DBG_NoDeactivation = 16,
  DBG_NoHelpText = 32,
  DBG_DrawText = 64,
  DBG_ProfileTimings = 128,
  DBG_EnableSatComparison = 256,
  DBG_DisableBulletLCP = 512,
  DBG_EnableCCD = 1024,
  DBG_DrawConstraints = (1 << 11),
  DBG_DrawConstraintLimits = (1 << 12),
  DBG_FastWireframe = (1<<13),
  DBG_MAX_DEBUG_DRAW_MODE
}
*/

class DebugDrawer : public btIDebugDraw
{
        int m_debugMode;
				void (*m_line_callback)(float*);
   public:
        DebugDrawer();
        virtual void   drawLine(const btVector3& from,const btVector3& to,const btVector3& color);
        virtual void   drawContactPoint(const btVector3& PointOnB,const btVector3& normalOnB,btScalar distance,int lifeTime,const btVector3& color);
        virtual void   reportErrorWarning(const char* warningString);
        virtual void   draw3dText(const btVector3& location,const char* textString);
        virtual void   setDebugMode(int debugMode);
        virtual int    getDebugMode() const { return m_debugMode; }
				        void	 set_line_callback(void (*)(float*));
};

#endif
