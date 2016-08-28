import PiedPiper

/// A reified batchGetAll
public final class BatchAllCache<KeySeq: SequenceType, Cache: CacheLevel where KeySeq.Generator.Element == Cache.KeyType>: CacheLevel {
  /// A sequence of keys for the wrapped cache
  public typealias KeyType = KeySeq
  /// An array of output elements
  public typealias OutputType = [Cache.OutputType]

  private let cache: Cache
  
  public init(cache: Cache) {
    self.cache = cache
  }

  /**
   Dispatch each key in the sequence in parallel
   Merge the results -- if any key fails, it all fails
  */
  public func get(key: KeyType) -> Future<OutputType> {
    return key.traverse(cache.get)
  }

  /**
  Zip the keys with the values and set them all
  */
  public func set(value: OutputType, forKey key: KeyType) -> Future<()> {
    return zip(value, key)
      .map(cache.set)
      .reduce(Future<()>(), combine: { previous, current in
        previous.flatMap { current }
      })
  }

  public func clear() {
    cache.clear()
  }

  public func onMemoryWarning() {
    cache.onMemoryWarning()
  }
}

extension CacheLevel {
  /**
   Wrap a <K, V> cache into a <Sequence<K>, [V]> cache where
   each k in Sequence<K> is dispatched in parallel and if any K fails,
   it all fails
   */
  public func allBatch<KeySeq: SequenceType where KeySeq.Generator.Element == Self.KeyType>() -> BatchAllCache<KeySeq, Self>  {
    return BatchAllCache(cache: self)
  }
}