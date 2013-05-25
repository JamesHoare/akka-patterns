package org.eigengo.akkapatterns.core.recog

import com.xuggle.xuggler._
import javax.imageio.ImageIO
import java.io.File

/**
 * @author janmachacek
 */
trait H264Operations {
  /*
  val container = IContainer.make()
  container.open("/Users/janmachacek/2.mov", IContainer.Type.READ, null)
  val videoStream = container.getStream(0)
  val videoCoder = videoStream.getStreamCoder
  videoCoder.open(IMetaData.make(), IMetaData.make())

  val packet = IPacket.make()
  while (container.readNextPacket(packet) >= 0) {
    val picture = IVideoPicture.make(videoCoder.getPixelType, videoCoder.getWidth, videoCoder.getHeight)
    packet.getSize
    var offset = 0
    while (offset < packet.getSize) {
      val bytesDecoded = videoCoder.decodeVideo(picture, packet, offset)
      offset = offset + bytesDecoded
      if (picture.isComplete) {
        val javaImage = Utils.videoPictureToImage(picture)
        ImageIO.write(javaImage, "png", new File("/Users/janmachacek/2.png"))
      }
    }
  }
  videoCoder.close()
  videoCoder.close()
  */
}
