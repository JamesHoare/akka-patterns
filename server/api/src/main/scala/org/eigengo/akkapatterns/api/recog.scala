package org.eigengo.akkapatterns.api

import spray.routing.Directives
import org.eigengo.akkapatterns.domain.{DefaultTimeout, RecogSessionId}
import akka.actor.{Actor, ActorRef}
import org.eigengo.akkapatterns.core.recog._
import org.apache.commons.codec.binary.Base64
import spray.http._
import concurrent.ExecutionContext
import java.nio.ByteBuffer
import java.io.FileOutputStream
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

trait ByteBufferOperations {

  implicit class RichByteBuffer(val underlying: ByteBuffer) {
    def ++=(that: ByteBuffer) {
      val pos = that.position()
      that.position(0)
      underlying.put(that)
      that.position(pos)
    }

  }

}

class StreamingRecogService(coordinator: ActorRef, origin: String)(implicit executionContext: ExecutionContext) extends Actor with ByteBufferOperations {
  var os: FileOutputStream = _
//  final val OneMeg = 1024 * 1024         // 1 MiB
//  final val FrameBlocks = 10 * 1024      // 50 kiB
//  final val HeaderBlock = 8192
//
//
//
//  val frameBuffer  = ByteBuffer.allocate(OneMeg)
//  val headerBuffer = ByteBuffer.allocate(HeaderBlock)
//  var at = 0
//  var counter = 0

  def receive = {
    case ChunkedRequestStart(HttpRequest(HttpMethods.POST, "/recog/stream", _, entity, _)) =>
      println("start" + entity.asString)
      os = new FileOutputStream("/Users/janmachacek/foo.mov")
    case MessageChunk(body, extensions) =>
      print(".")
      os.write(body)
//      if (headerBuffer.hasRemaining) {
//        val count = Math.min(body.length, headerBuffer.remaining())
//        headerBuffer.put(body, 0, count)
//        if (count < body.length) frameBuffer.put(body, count, body.length - count)
//      } else if (frameBuffer.hasRemaining) frameBuffer.put(body, 0, Math.min(body.length, frameBuffer.remaining()))
//
//      if (frameBuffer.position() > FrameBlocks) {
//        try {
//          val video: RichByteBuffer = ByteBuffer.allocate(OneMeg + HeaderBlock)
//          video ++= headerBuffer
//          video ++= frameBuffer
//
//          counter = counter + 1
//          video.underlying.position(0)
//          val g = new FrameGrab(new ByteBufferSeekableByteChannel(video.underlying))
//          val frame = g.getFrame
//          val outputfile = new File(s"/Users/janmachacek/Tmp/saved$counter.png")
//          ImageIO.write(frame, "png", outputfile)
//          frameBuffer.position(0)
//        } catch {
//          case t: Throwable => // noop
//        }
//      }
    case ChunkedMessageEnd(extensions, trailer) =>
      os.close()
      println("end")
      sender ! HttpResponse(entity = "!! end")
    case _ =>
      sender ! HttpResponse(entity = "Do chunked post instead")
  }

}