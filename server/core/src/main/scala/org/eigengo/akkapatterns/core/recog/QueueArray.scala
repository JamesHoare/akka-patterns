package org.eigengo.akkapatterns.core.recog

/**
 * Adds convenience functions and wraps ``Array[Byte]`` in a new type
 */
case class QueueArray(data: Array[Byte]) extends AnyVal {

  /**
   * Appends ``data`` to this array
   * @param data the data to be appended
   * @return the appended instance
   */
  def append(data: Array[Byte]): QueueArray = {
    val newData = Array.ofDim[Byte](data.length + this.data.length)
    Array.copy(this.data, 0, newData, 0, this.data.length)
    Array.copy(data, this.data.length, newData, this.data.length, data.length)
    QueueArray(newData)
  }

  /**
   * Removes ``bytes`` from the beginning of the ``data``.
   * @param bytes the number of bytes to remove
   * @return the removed instance
   */
  def remove(bytes: Int): QueueArray = {
    if (bytes > data.length) throw new IllegalArgumentException("Remove more than length")
    val newData = Array.ofDim[Byte](data.length - bytes)
    Array.copy(data, bytes, newData, 0, data.length - bytes)
    QueueArray(newData)
  }

}
