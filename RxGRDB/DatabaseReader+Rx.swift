import GRDB
import RxSwift

/// We want the `rx` joiner on DatabaseReader.
/// Normally we'd use ReactiveCompatible. But ReactiveCompatible is unable to
/// define `rx` on existentials as well:
///
///     let reader: DatabaseReader
///     reader.rx...
///
/// :nodoc:
extension DatabaseReader {
    public var rx: Reactive<AnyDatabaseReader> {
        return Reactive(AnyDatabaseReader(self))
    }
}

extension Reactive where Base: DatabaseReader {
    /// Returns a Single that asynchronously emits the fetched value.
    ///
    ///     let dbQueue = DatabaseQueue()
    ///     let players: Single<[Player]> = dbQueue.rx.read { db in
    ///         try Player.fetchAll(db)
    ///     }
    ///
    /// By default, returned values are emitted on the main dispatch queue. If
    /// you give a *scheduler*, values are emitted on that scheduler.
    ///
    /// - parameter value: A closure which accesses the database.
    /// - parameter scheduler: The scheduler on which the single completes.
    ///   Defaults to MainScheduler.instance.
    public func read<T>(
        observeOn scheduler: ImmediateSchedulerType = MainScheduler.instance,
        value: @escaping (Database) throws -> T)
        -> Single<T>
    {
        let reader = base
        return Single
            .create { observer in
                reader.asyncRead { db in
                    do {
                        try observer(.success(value(db.get())))
                    } catch {
                        observer(.error(error))
                    }
                }
                return Disposables.create { }
            }
            .observeOn(scheduler)
    }
}

/// :nodoc:
extension DatabaseReader where Self: ReactiveCompatible {
    public var rx: Reactive<Self> {
        return Reactive(self)
    }
}
