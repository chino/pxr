#include <stdio.h>
#include "debug_drawer.h"

DebugDrawer::DebugDrawer()
{
	m_debugMode = 0;
	m_line_callback = NULL;
}

void DebugDrawer::drawLine(const btVector3& from,const btVector3& to,const btVector3& color)
{
	if(!m_line_callback)
		return;
	float data[9] = {
			from.getX(), from.getY(), from.getZ(),
			to.getX(), to.getY(), to.getZ(),
			color.getX(), color.getY(), color.getZ()
	};
	m_line_callback(&data[0]);
}

void DebugDrawer::setDebugMode(int debugMode)
	{ m_debugMode = debugMode; }

void DebugDrawer::set_line_callback(void (*f)(float*))
	{ m_line_callback = f; }

void DebugDrawer::draw3dText(const btVector3& location,const char* s)
	{ printf("text @ %f,%f,%f %s\n", location.getX(), location.getY(), location.getZ(), s); }

void DebugDrawer::reportErrorWarning(const char* warningString)
	{ printf(warningString); }

void DebugDrawer::drawContactPoint(
	const btVector3& pointOnB,const btVector3& normalOnB,
	btScalar distance,int lifeTime,const btVector3& color)
	{}
