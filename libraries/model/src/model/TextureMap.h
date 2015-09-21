//
//  TextureMap.h
//  libraries/model/src/model
//
//  Created by Sam Gateau on 5/6/2015.
//  Copyright 2014 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//
#ifndef hifi_model_TextureMap_h
#define hifi_model_TextureMap_h

#include "gpu/Texture.h"

#include "Material.h"
#include "Transform.h"

#include <qurl.h>

class QImage;

namespace model {

typedef glm::vec3 Color;

class TextureUsage {
public:
    gpu::Texture::Type _type{ gpu::Texture::TEX_2D };
    Material::MapFlags _materialUsage{ MaterialKey::DIFFUSE_MAP };

    int _environmentUsage = 0;
};

// TextureSource is a specialized version of the gpu::Texture::Storage
// It provides the mechanism to create a texture from a Url and the intended usage 
// that guides the internal format used
class TextureSource {
public:
    TextureSource();
    ~TextureSource();

    const QUrl& getUrl() const { return _imageUrl; }
    gpu::Texture::Type getType() const { return _usage._type; }
    const gpu::TexturePointer getGPUTexture() const { return _gpuTexture; }

    void reset(const QUrl& url, const TextureUsage& usage);

    void resetTexture(gpu::Texture* texture);

    bool isDefined() const;
    
    static gpu::Texture* create2DTextureFromImage(const QImage& image, const std::string& srcImageName);
    static gpu::Texture* createNormalTextureFromBumpImage(const QImage& image, const std::string& srcImageName);
    static gpu::Texture* createCubeTextureFromImage(const QImage& image, const std::string& srcImageName);

protected:
    gpu::TexturePointer _gpuTexture;
    TextureUsage _usage;
    QUrl _imageUrl;
};
typedef std::shared_ptr< TextureSource > TextureSourcePointer;



class TextureMap {
public:
    TextureMap() {}

    void setTextureSource(TextureSourcePointer& texStorage);

    bool isDefined() const;
    gpu::TextureView getTextureView() const;

    void setTextureTransform(const Transform& texcoordTransform);
    const Transform& getTextureTransform() const { return _texcoordTransform; }

    void setLightmapOffsetScale(float offset, float scale);
    const glm::vec2& getLightmapOffsetScale() const { return _lightmapOffsetScale; }

protected:
    TextureSourcePointer _textureSource;

    Transform _texcoordTransform;
    glm::vec2 _lightmapOffsetScale{ 0.0f, 1.0f };
};
typedef std::shared_ptr< TextureMap > TextureMapPointer;

};

#endif // hifi_model_TextureMap_h

