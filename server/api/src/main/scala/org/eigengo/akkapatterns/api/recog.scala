package org.eigengo.akkapatterns.api

import spray.routing.Directives
import org.eigengo.akkapatterns.domain.{DefaultTimeout, RecogSessionId}
import akka.actor.{Actor, ActorRef}
import org.eigengo.akkapatterns.core.recog._
import org.apache.commons.codec.binary.Base64
import spray.http._
import concurrent.ExecutionContext
import org.jcodec.api.FrameGrab
import org.jcodec.common.ByteBufferSeekableByteChannel
import java.nio.ByteBuffer
import java.io.File
import javax.imageio.ImageIO
import org.eigengo.akkapatterns.core.recog.RecogSessionRejected
import org.eigengo.akkapatterns.core.recog.RecogSessionCompleted
import org.eigengo.akkapatterns.core.recog.RecogSessionAccepted
import spray.routing.RequestContext
import spray.http.ChunkedRequestStart
import spray.http.HttpHeaders.RawHeader
import org.eigengo.akkapatterns.core.recog.ProcessImage
import spray.http.ChunkedMessageEnd
import spray.http.HttpResponse

class RecogService(coordinator: ActorRef, origin: String)(implicit executionContext: ExecutionContext) extends Directives with CrossLocationRouteDirectives with EndpointMarshalling
  with DefaultTimeout with RecogFormats {
  val headers = RawHeader("Access-Control-Allow-Origin", origin) :: Nil

  import akka.pattern.ask

  def image(sessionId: RecogSessionId)(ctx: RequestContext) {
    (coordinator ? ProcessImage(sessionId, Base64.decodeBase64(ctx.request.entity.buffer))) onSuccess {
      case x: RecogSessionAccepted  => ctx.complete(StatusCodes.Accepted,            headers, x)
      case x: RecogSessionRejected  => ctx.complete(StatusCodes.BadRequest,          headers, x)
      case x: RecogSessionCompleted => ctx.complete(StatusCodes.OK,                  headers, x)
      case x                        => ctx.complete(StatusCodes.InternalServerError, headers, x.toString)
    }
  }

  val route =
    path("recog/single") {
      post {
        complete {
          (coordinator ? Begin).map(_.toString)
        }
      }
    } ~
    path("recog/single" / JavaUUID) { sessionId =>
      post {
        image(sessionId)
      }
    }

}

class StreamingRecogService(coordinator: ActorRef, origin: String)(implicit executionContext: ExecutionContext) extends Actor {
  val buffer = new ByteBufferSeekableByteChannel(ByteBuffer.allocateDirect(1024 * 1024 * 20))
  var counter = 0

  def receive = {
    case ChunkedRequestStart(HttpRequest(HttpMethods.POST, "/recog/stream", _, entity, _)) =>
      println("start")
    case MessageChunk(body, extensions) =>
      buffer.write(ByteBuffer.wrap(body))

      val at = buffer.position()
      try {
        counter = counter + 1
        val g = new FrameGrab(buffer)
        val frame = g.getFrame
        val outputfile = new File(s"/Users/janmachacek/Tmp/saved$counter.png")
        ImageIO.write(frame, "png", outputfile)
      } catch {
        case t: Throwable => buffer.position(at); print("x" + buffer.position())
      }

      print(".")
    case ChunkedMessageEnd(extensions, trailer) =>
      println("end")
      sender ! HttpResponse(entity = "!! end")
  }

}