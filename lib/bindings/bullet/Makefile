CXX=g++

FLAGS=-pipe #-g
CXXFLAGS=$(FLAGS) -Wall -Wextra
LDFLAGS=$(FLAGS)

LDFLAGS+= -L./linux/usr/local/lib
CXXFLAGS+= -I./linux/usr/local/include -I.
LIBS+= -lBulletSoftBody -lBulletDynamics
LIBS+= -lBulletCollision -lLinearMath

SDL_CONFIG=sdl-config
CXXFLAGS+= `$(SDL_CONFIG) --cflags`
LIBS+= `$(SDL_CONFIG) --libs`

INCLUDE=$(wildcard *.h)
SRC=$(wildcard *.cpp)
OBJS=$(patsubst %.cpp,%.o,$(SRC))

SO=physics_bullet.so
LDFLAGS+= -shared -Wl,-soname,$(SO).1

all: $(SO)

$(SO): $(OBJS)
	$(CXX) -o $(SO) $(OBJS) $(LDFLAGS) $(LIBS)

$(OBJS): $(INCLUDE) $(SRC)

clean:
	$(RM) $(OBJS) $(SO)

.PHONY: all clean
