%module FTGL
%include "typemaps.i"

%{
#include "FTGLExtrdFont.h"
#include "FTGLOutlineFont.h"
#include "FTGLPolygonFont.h"
#include "FTGLTextureFont.h"
#include "FTGLPixmapFont.h"
#include "FTGLBitmapFont.h"
%}


//  result = (unsigned int)(static_cast<const FTFont*>((FTGLTextureFont const *)arg1))->FaceSize();


typedef int FT_Error;

%rename(SetFaceSize) *::FaceSize(const unsigned int size, const unsigned int res = 72);


%rename(BitmapFont) FTGLBitmapFont;
class FTGLBitmapFont
{
    public:
        FTGLBitmapFont( const char* fontFilePath);
        bool Attach( const char* fontFilePath);
        // bool CharMap( FT_Encoding encoding );
        // unsigned int CharMapCount();
        // FT_Encoding* CharMapList();
        virtual bool FaceSize( const unsigned int size, const unsigned int res = 72);
        unsigned int FaceSize() const;
        void UseDisplayList( bool useList);
        float Ascender() const;
        float Descender() const;
        float LineHeight() const;
        void BBox( const char* string, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT);
        float Advance( const char* string);
        virtual void Render( const char* string );
        FT_Error Error() const { return err;}
};

%rename(ExtrdFont) FTGLExtrdFont;
class FTGLExtrdFont
{
    public:
        FTGLExtrdFont( const char* fontFilePath);
        bool Attach( const char* fontFilePath);
        // bool CharMap( FT_Encoding encoding );
        // unsigned int CharMapCount();
        // FT_Encoding* CharMapList();
        virtual bool FaceSize( const unsigned int size, const unsigned int res = 72);
        unsigned int FaceSize() const;
        virtual void Depth( float depth);
        void UseDisplayList( bool useList);
        float Ascender() const;
        float Descender() const;
        float LineHeight() const;
        void BBox( const char* string, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT);
        float Advance( const char* string);
        virtual void Render( const char* string );
        FT_Error Error() const { return err;}
};

%rename(OutlineFont) FTGLOutlineFont;
class FTGLOutlineFont
{
    public:
        FTGLOutlineFont( const char* fontFilePath);
        bool Attach( const char* fontFilePath);
        // bool CharMap( FT_Encoding encoding );
        // unsigned int CharMapCount();
        // FT_Encoding* CharMapList();
        virtual bool FaceSize( const unsigned int size, const unsigned int res = 72);
        unsigned int FaceSize() const;
        void UseDisplayList( bool useList);
        float Ascender() const;
        float Descender() const;
        float LineHeight() const;
        void BBox( const char* string, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT);
        float Advance( const char* string);
        virtual void Render( const char* string );
        FT_Error Error() const { return err;}
};

%rename(PixmapFont) FTGLPixmapFont;
class FTGLPixmapFont
{
    public:
        FTGLPixmapFont( const char* fontFilePath);
        bool Attach( const char* fontFilePath);
        // bool CharMap( FT_Encoding encoding );
        // unsigned int CharMapCount();
        // FT_Encoding* CharMapList();
        virtual bool FaceSize( const unsigned int size, const unsigned int res = 72);
        unsigned int FaceSize() const;
        void UseDisplayList( bool useList);
        float Ascender() const;
        float Descender() const;
        float LineHeight() const;
        void BBox( const char* string, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT);
        float Advance( const char* string);
        virtual void Render( const char* string );
        FT_Error Error() const { return err;}
};

%rename(PolygonFont) FTGLPolygonFont;
class FTGLPolygonFont
{
    public:
        FTGLPolygonFont( const char* fontFilePath);
        bool Attach( const char* fontFilePath);
        // bool CharMap( FT_Encoding encoding );
        // unsigned int CharMapCount();
        // FT_Encoding* CharMapList();
        virtual bool FaceSize( const unsigned int size, const unsigned int res = 72);
        unsigned int FaceSize() const;
        void UseDisplayList( bool useList);
        float Ascender() const;
        float Descender() const;
        float LineHeight() const;
        void BBox( const char* string, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT);
        float Advance( const char* string);
        virtual void Render( const char* string );
        FT_Error Error() const { return err;}
};

%rename(TextureFont) FTGLTextureFont;
class FTGLTextureFont
{
    public:
        FTGLTextureFont( const char* fontFilePath);
        bool Attach( const char* fontFilePath);
        // bool CharMap( FT_Encoding encoding );
        // unsigned int CharMapCount();
        // FT_Encoding* CharMapList();
        virtual bool FaceSize( const unsigned int size, const unsigned int res = 72);
        unsigned int FaceSize() const;
        void UseDisplayList( bool useList);
        float Ascender() const;
        float Descender() const;
        float LineHeight() const;
        void BBox( const char* string, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT, float& OUTPUT);
        float Advance( const char* string);
        virtual void Render( const char* string );
        FT_Error Error() const { return err;}
};


