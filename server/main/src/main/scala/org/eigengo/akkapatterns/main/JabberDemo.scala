package org.eigengo.akkapatterns.main

import org.jivesoftware.smack.{SASLAuthentication, ConnectionConfiguration, XMPPConnection}
import org.jivesoftware.smack.packet.{Message, Presence}

/**
 * @author janmachacek
 */
object JabberDemo {

  def main(args: Array[String]) {
    val config = new ConnectionConfiguration("jabber.org", 5222, "jabber.org")

    val conn1 = new XMPPConnection(config)
    SASLAuthentication.supportSASLMechanism("PLAIN", 0)
    conn1.connect()
    //conn1.login("jan.machacek@gmail.com", "^Gen0me128*")
    conn1.login("scaladays", "dFvJGY86")

    val message = new Message("scaladays@jabber.org", Message.Type.normal)
    message.setBody("Hahahaah")
    conn1.sendPacket(message)

    conn1.disconnect()
  }

}
