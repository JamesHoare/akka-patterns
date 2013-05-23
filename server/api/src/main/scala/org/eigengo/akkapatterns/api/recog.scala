package org.eigengo.akkapatterns.api

import spray.routing.Directives
import org.eigengo.akkapatterns.domain.{DefaultTimeout, RecogSessionId}
import akka.actor.{Actor, ActorRef}
import org.eigengo.akkapatterns.core.recog._
import org.apache.commons.codec.binary.Base64
import spray.http._
import concurrent.ExecutionContext
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
import java.util.UUID
import akka.pattern.ask
import scala.util.{Failure, Success}

class RecogService(coordinator: ActorRef, origin: String)(implicit executionContext: ExecutionContext) extends Directives with CrossLocationRouteDirectives with EndpointMarshalling
  with DefaultTimeout with RecogFormats {
  val headers = RawHeader("Access-Control-Allow-Origin", origin) :: Nil

  def image(sessionId: RecogSessionId)(ctx: RequestContext) {
    (coordinator ? ProcessImage(sessionId, Base64.decodeBase64(ctx.request.entity.buffer))) onSuccess {
      case x: RecogSessionAccepted  => ctx.complete(StatusCodes.Accepted,            headers, x)
      case x: RecogSessionRejected  => ctx.complete(StatusCodes.BadRequest,          headers, x)
      case x: RecogSessionCompleted => ctx.complete(StatusCodes.OK,                  headers, x)
      case x                        => ctx.complete(StatusCodes.InternalServerError, headers, x.toString)
    }
  }

  val route =
    path("recog") {
      post {
        complete {
          (coordinator ? Begin).map(_.toString)
        }
      }
    } ~
    path("recog/static" / JavaUUID) { sessionId =>
      post {
        image(sessionId)
      }
    }

}

class StreamingRecogService(coordinator: ActorRef, origin: String)(implicit executionContext: ExecutionContext) extends Actor with DefaultTimeout {
  var os: FileOutputStream = _

  def receive = {
    // POST to /recog
    case HttpRequest(HttpMethods.POST, "/recog", _, _, _) =>
      val client = sender
      (coordinator ? Begin).map(_.toString).onComplete {
        case Success(sessionId) => client ! HttpResponse(entity = sessionId)
        case Failure(ex)        => client ! HttpResponse(entity = ex.getMessage, status = StatusCodes.InternalServerError)
      }

    // stream to /recog/stream/:id
    case ChunkedRequestStart(HttpRequest(HttpMethods.POST, uri, _, entity, _)) if uri startsWith "/recog/stream/" =>
      val sessionId = UUID.fromString(uri.substring(14))
      coordinator ! ProcessFrame()
      print("start" + entity.asString)
      os = new FileOutputStream("/Users/janmachacek/" + sessionId + ".mov")
    case MessageChunk(body, extensions) =>
      print(".")
      os.write(body)
    case ChunkedMessageEnd(extensions, trailer) =>
      os.close()
      println("end")
      sender ! HttpResponse(entity = "!! end")

    // POST to /recog/static/:id
    case HttpRequest(HttpMethods.POST, uri, _, entity, _) if uri startsWith "/recog/static/" =>
      sender ! HttpResponse(entity = "Not implemented", status = StatusCodes.NotImplemented)

    // all other requests
    case _ =>
      sender ! HttpResponse(entity = "Do chunked post instead", status = StatusCodes.BadRequest)
  }

}