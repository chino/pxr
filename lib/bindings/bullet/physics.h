#ifndef PHYSICS_INCLUDED
#define PHYSICS_INCLUDED
#include <btBulletDynamicsCommon.h>

extern "C" {

void physics_debug( btRigidBody * b );
void physics_init( void (*line_callback)(float*) );
void physics_debug_draw( void );
void physics_cleanup( void );

void physics_gravity( float x, float y, float z );

void physics_remove_body( btRigidBody* body );

bool physics_perform_ray_cast_on_bvh(
	btRigidBody* body,
	float fx, float fy, float fz, // from
	float tx, float ty, float tz // to
);

btRigidBody* physics_create_static_bvh_tri_mesh(
		int     numTriangles,
		int   * triangleIndexBase,
		int  	  triangleIndexStride,
		int  	  numVertices,
		float *	vertexBase,
		int  	  vertexStride	 
);

void physics_set_friction(
	btRigidBody * body,
	float friction
);

btRigidBody* physics_create_sphere(
  float mass,
  float radius,
	float lin_drag, float ang_drag,
  float vx, float vy, float vz, // position
  float qx, float qy, float qz, float qw // orientation
);

btRigidBody* physics_create_plane(
  float mass,
  float constant,
  float nx, float ny, float nz, // normal
  float vx, float vy, float vz,
  float qx, float qy, float qz, float qw
);

void physics_body_transform(
  btRigidBody * b,
  float vec[3],
	float quat[4]
);

void physics_body_apply_torque(
	btRigidBody * b,
	float x, float y, float z
);

void physics_body_apply_relative_torque(
	btRigidBody * b,
	float x, float y, float z
);

void physics_body_apply_central_force(
	btRigidBody * b,
	float x, float y, float z
);

void physics_body_apply_relative_central_force(
	btRigidBody * b,
	float x, float y, float z
);

void physics_step( float step, int steps );

} 
#endif
