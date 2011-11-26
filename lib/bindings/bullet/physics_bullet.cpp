#include <stdio.h>
#include <btBulletDynamicsCommon.h>
#include <bullet/BulletCollision/CollisionShapes/btTriangleCallback.h>
#include "physics.h"
#include "debug_drawer.h"

btBroadphaseInterface* broadphase;
btDefaultCollisionConfiguration* collisionConfiguration;
btCollisionDispatcher* dispatcher;
btSequentialImpulseConstraintSolver* solver;
btDiscreteDynamicsWorld* dynamicsWorld;
DebugDrawer debugDrawer;

void physics_debug( btRigidBody * b )
{
	printf("activation state: %d\n",b->getActivationState());
	//printf("linear sleeping: %f\n",b->getAngularSleepingThreshold());
	//printf("angular sleeping: %f\n",b->getAngularSleepingThreshold());
	puts("---\n");
}

void physics_gravity( float x, float y, float z )
{
	dynamicsWorld->setGravity(btVector3(x,y,z));
}

void physics_init( void (*line_callback)(float*) )
{
	// the aabb broad phase
	broadphase = new btDbvtBroadphase();

	// default configuration for near phase collision detection
	collisionConfiguration = new btDefaultCollisionConfiguration();
	dispatcher = new btCollisionDispatcher(collisionConfiguration);

	// the collision solver
	solver = new btSequentialImpulseConstraintSolver;

	// create the world
	dynamicsWorld = new btDiscreteDynamicsWorld(
			dispatcher,broadphase,solver,collisionConfiguration);

	// enable debugging
	debugDrawer.set_line_callback(line_callback);
	debugDrawer.setDebugMode(btIDebugDraw::DBG_DrawWireframe | btIDebugDraw::DBG_DrawAabb);
	dynamicsWorld->setDebugDrawer(&debugDrawer);

	// cleanup later
	atexit(physics_cleanup);
}

void physics_cleanup( void )
{
    delete dynamicsWorld;
    delete solver;
    delete dispatcher;
    delete collisionConfiguration;
    delete broadphase;
}

void physics_remove_body( btRigidBody * body )
{
	dynamicsWorld->removeRigidBody( body );
}

void physics_set_friction(
	btRigidBody * body,
	float friction
)
{
	body->setFriction( friction );
}

void physics_world_add_body(
	btRigidBody * body,
	short group,
	short mask
)
{
	dynamicsWorld->addRigidBody(body, group, mask);
}

typedef void (*motion_state_callback)(
	float x, float y, float z,
	float qx, float qy, float qz, float qw
);

class MyMotionState : public btMotionState {
public:
    MyMotionState( const btTransform &initialpos, motion_state_callback _callback ){
        mPos1 = initialpos;
				callback = _callback;
    }
    virtual ~MyMotionState() {}
    virtual void getWorldTransform(btTransform &worldTrans) const { worldTrans = mPos1; }
    virtual void setWorldTransform(const btTransform &worldTrans) {
				if(!callback)return;
        btQuaternion rot = worldTrans.getRotation();
        btVector3 pos = worldTrans.getOrigin();
				callback(
  	     pos.x(), pos.y(), pos.z(),
 	       rot.x(), rot.y(), rot.z(), rot.w()
				);
    }
protected:
    btTransform mPos1;
		motion_state_callback callback;
};

btRigidBody* physics_create_body(
	btCollisionShape * shape,
	float mass, float lin_drag, float ang_drag,
	float vx, float vy, float vz,
	float qx, float qy, float qz, float qw,
	motion_state_callback _callback
)
{
	MyMotionState* motionState =
		new MyMotionState(
			btTransform(
				btQuaternion(qx,qy,qz,qw),
				btVector3(vx,vy,vz)
			),
			_callback
		);
	btVector3 Inertia(0,0,0);
	shape->calculateLocalInertia(mass,Inertia);
	btRigidBody::btRigidBodyConstructionInfo
		RigidBodyCI(
			mass,motionState,shape,Inertia);
	btRigidBody* rigidBody = 
		new btRigidBody(RigidBodyCI);
	rigidBody->setDamping(lin_drag,ang_drag);
	return rigidBody;
}

btRigidBody* physics_create_box(
	float mass,
	float sx, float sy, float sz, // size of box (half extents)
	float lin_drag, float ang_drag,
	float vx, float vy, float vz, // position
	float qx, float qy, float qz, float qw, // orientation
  float lx, float ly, float lz, // lin velocity (world)
  float ax, float ay, float az,  // ang velocity (local)
	motion_state_callback _callback
)
{
	btRigidBody * b = physics_create_body(
		new btBoxShape( btVector3(sx,sy,sz) ),
		mass, lin_drag, ang_drag,
		vx,  vy,  vz,
		qx,  qy,  qz,  qw,
		_callback
	);
	physics_body_set_linear_velocity(
		b, lx, ly, lz
	);
	physics_body_set_relative_angular_velocity(
		b, ax, ay, az
	);
	return b;
}

btRigidBody* physics_create_sphere(
	float mass,
	float radius,
	float lin_drag, float ang_drag,
	float vx, float vy, float vz, // position
	float qx, float qy, float qz, float qw, // orientation
  float lx, float ly, float lz, // lin velocity (world)
  float ax, float ay, float az,  // ang velocity (local)
	motion_state_callback _callback
)
{
	btRigidBody * b = physics_create_body(
		new btSphereShape( radius ),
		mass, lin_drag, ang_drag,
		vx,  vy,  vz,
		qx,  qy,  qz,  qw,
		_callback
	);
	physics_body_set_linear_velocity(
		b, lx, ly, lz
	);
	physics_body_set_relative_angular_velocity(
		b, ax, ay, az
	);
	return b;
}

btRigidBody* physics_create_plane(
	float mass,
	float constant,
	float nx, float ny, float nz,
	float vx, float vy, float vz,
	float qx, float qy, float qz, float qw
)
{
	return physics_create_body(
		new btStaticPlaneShape(
			btVector3(nx,ny,nz),
			constant
		),
		mass, 0.0f, 0.0f,
		vx,  vy,  vz,
		qx,  qy,  qz,  qw,
		NULL
	);
}

struct RayTestCallback : public btTriangleCallback
{
	bool hit;
	RayTestCallback(){ this->hit = false; }
	virtual void processTriangle(btVector3* triangle, int partId, int triangleIndex)
		{ this->hit = true; }
};

bool physics_perform_ray_cast_on_bvh(
	btRigidBody* body,
	float fx, float fy, float fz, // from
	float tx, float ty, float tz // to
)
{
  RayTestCallback myRayTestCallback;
	btVector3 from = btVector3(fx,fy,fz);
	btVector3 to = btVector3(tx,ty,tz);
	btBvhTriangleMeshShape* shape = 
		(btBvhTriangleMeshShape*) 
			body->getCollisionShape();
	shape->performRaycast(
		&myRayTestCallback, from, to );
	return myRayTestCallback.hit;
}

btRigidBody* physics_create_static_bvh_tri_mesh(
		int     numTriangles,
		int   * triangleIndexBase,
		int  	  triangleIndexStride,
		int  	  numVertices,
		float *	vertexBase,
		int  	  vertexStride	 
)
{
	return physics_create_body(
		new btBvhTriangleMeshShape(
			new btTriangleIndexVertexArray(
				numTriangles,
				triangleIndexBase,
				triangleIndexStride,
				numVertices,
				vertexBase,
				vertexStride
			),
			true, // useQuantizedAabbCompression
			true // buildBvh
		),
		0,0,0,
		0,0,0,
		0,0,0,1,
		NULL
	);
}

void physics_draw( void )
{
	dynamicsWorld->debugDrawWorld();
}

void physics_step( float time_passed, int max_steps, float step_interval )
{
	dynamicsWorld->stepSimulation( time_passed, max_steps, step_interval );
}

void physics_debug_draw( void )
{
	physics_draw();
}

void physics_body_transform(
	btRigidBody * b,
	float v[3],
	float q[4]
)
{
	btTransform t;
	b->getMotionState()->getWorldTransform(t);
	v[0] = t.getOrigin().getX();
	v[1] = t.getOrigin().getY();
	v[2] = t.getOrigin().getZ();
	q[0] = t.getRotation().getX();
	q[1] = t.getRotation().getY();
	q[2] = t.getRotation().getZ();
	q[3] = t.getRotation().getW();
}

void physics_body_apply_torque(
	btRigidBody * b,
	float x, float y, float z
)
{
	b->activate();
	b->applyTorque(btVector3(x,y,z));
}

void physics_body_apply_relative_torque(
	btRigidBody * b,
	float x, float y, float z
)
{
	b->activate();
	btQuaternion q = b->getOrientation();
	btQuaternion q2 = q.normalize() * btQuaternion(x,y,z,0) * q.inverse();
	b->applyTorque( btVector3(q2.getX(),q2.getY(),q2.getZ()) );
}

void physics_body_apply_central_force(
	btRigidBody * b,
	float x, float y, float z
)
{
	b->activate();
	b->applyCentralForce(btVector3(x,y,z));
}

void physics_body_apply_relative_central_force(
	btRigidBody * b,
	float x, float y, float z
)
{
	b->activate();
	btVector3 relativeForce = btVector3(x,y,z);
	btMatrix3x3& boxRot = b->getWorldTransform().getBasis();
	btVector3 correctedForce = boxRot * relativeForce;
	b->applyCentralForce(correctedForce);
}

void physics_body_set_relative_angular_velocity(
	btRigidBody * b,
	float x, float y, float z
)
{
	b->activate();
	btQuaternion q = b->getOrientation();
	btQuaternion q2 = q.normalize() * btQuaternion(x,y,z,0) * q.inverse();
	b->setAngularVelocity( btVector3(q2.getX(),q2.getY(),q2.getZ()) );
}

void physics_body_set_linear_velocity(
	btRigidBody * b,
	float x, float y, float z
)
{
	b->activate();
	b->setLinearVelocity( btVector3(x,y,z) );
}
