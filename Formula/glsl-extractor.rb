class GlslExtractor < Formula
  desc "A tool to extract attributes and uniforms from GLSL source code"
  homepage "https://junckes.me/projects/glsl-extractor/"
  url "https://github.com/j-junckes/glsl_extractor/releases/download/v0.3.0/glsl_extractor_v0_3_0.tar.gz"
  sha256 "739182621cef591282b611a1fcc5b5038558987bdf7647dc5f3fbfc1dae14f36"
  head "https://github.com/j-junckes/glsl_extractor.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "git" => :build

  def install
    system "cmake", ".", "-GNinja", *std_cmake_args
    system "ninja"
    system "ninja", "install"
  end

  test do
    (testpath/"test.vsh").write <<~EOS
      #version 330 core
      layout (location = 0) in vec3 aPos;
      layout (location = 1) in vec2 aTexCoords;
  
      out vec2 TexCoords;
  
      uniform mat4 model;
      uniform mat4 view;
      uniform mat4 projection;
  
      void main()
      {
          TexCoords = aTexCoords;
          gl_Position = projection * view * model * vec4(aPos, 1.0);
      }
    EOS
  
    (testpath/"test.fsh").write <<~EOS
      #version 330 core
      out vec4 FragColor;
  
      in vec2 TexCoords;
  
      uniform sampler2D shaderTexture;
  
      void main()
      {
          FragColor = texture(shaderTexture, TexCoords);
      }
    EOS
  
    output = shell_output("#{bin}/glslextractor #{testpath}/test.vsh #{testpath}/test.fsh")
    expected_output = <<~EOS
      {
        "fragment": {
          "uniforms": [
            {
              "name": "shaderTexture",
              "type": "sampler2D"
            }
          ]
        },
        "vertex": {
          "attributes": [
            {
              "location": 0,
              "name": "aPos",
              "type": "vec3"
            },
            {
              "location": 1,
              "name": "aTexCoords",
              "type": "vec2"
            }
          ],
          "uniforms": [
            {
              "name": "model",
              "type": "mat4"
            },
            {
              "name": "view",
              "type": "mat4"
            },
            {
              "name": "projection",
              "type": "mat4"
            }
          ]
        }
      }
    EOS
  
    assert_equal expected_output, output.strip
  end
end
