package org.eigengo.akkapatterns.main

import com.xuggle.xuggler.{IVideoPicture, IPacket, IMetaData, IContainer}


/**
 * @author janmachacek
 */
object VideoDemo {

  def main(args: Array[String]) {
    val container = IContainer.make()
    container.open("/Users/janmachacek/foo.mov", IContainer.Type.READ, null)
    val videoStream = container.getStream(0)
    val videoCoder = videoStream.getStreamCoder
    videoCoder.open(IMetaData.make(), IMetaData.make())

    val packet = IPacket.make()
    while (container.readNextPacket(packet) >= 0) {
      val picture = IVideoPicture.make(videoCoder.getPixelType, videoCoder.getWidth, videoCoder.getHeight)
      packet.getSize

    }
  }

}
