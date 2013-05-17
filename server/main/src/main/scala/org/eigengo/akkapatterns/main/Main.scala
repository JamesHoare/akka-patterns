package org.eigengo.akkapatterns.main

import akka.actor.ActorSystem
import org.eigengo.akkapatterns.domain.{Settings, NoSqlConfig, Configuration}
import org.eigengo.akkapatterns.core.{LocalAmqpServerCore, ServerCore}
import org.eigengo.akkapatterns.web.Web
import org.eigengo.akkapatterns.api.Api
import akka.util.Timeout
import com.typesafe.config.{ConfigResolveOptions, ConfigParseOptions, ConfigFactory}
import org.jcodec.api.FrameGrab
import java.io.File
import javax.imageio.ImageIO

object Main {

  def main(args: Array[String]) {
//    val f = FrameGrab.getFrame(new File("/Users/janmachacek/Desktop/x.mp4"), 8000)
//    ImageIO.write(f, "png", new File("/Users/janmachacek/Tmp/x.png"))

    implicit val system = ActorSystem("AkkaPatterns",
      ConfigFactory.load("application", ConfigParseOptions.defaults().setAllowMissing(false), ConfigResolveOptions.defaults()))

    class Application(val actorSystem: ActorSystem) extends Configuration with NoSqlConfig with ServerCore with LocalAmqpServerCore with Api with Web {

      implicit val timeout = Timeout(30000)

      configure(mongo(Settings.main.db.mongo))
    }


    new Application(system)

    sys.addShutdownHook {
      system.shutdown()
    }
  }

}
