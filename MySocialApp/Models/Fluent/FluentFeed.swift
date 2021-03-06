import Foundation
import RxSwift

public class FluentFeed {
    private static let PAGE_SIZE = 10
    
    var session: Session
    
    init(_ session:  Session) {
        self.session = session
    }
    
    private func stream(_ page: Int, _ to: Int, _ obs: AnyObserver<Feed>) {
        if to > 0 {
            let _ = session.clientService.feed.list(page, size: min(FluentFeed.PAGE_SIZE,to - (page * FluentFeed.PAGE_SIZE))).subscribe {
                e in
                if let e = e.element?.array {
                    let _ = e.map { obs.onNext($0) }
                    if e.count < FluentFeed.PAGE_SIZE {
                        obs.onCompleted()
                    } else {
                        self.stream(page + 1, to - FluentFeed.PAGE_SIZE, obs)
                    }
                } else {
                    obs.onCompleted()
                }
            }
        } else {
            obs.onCompleted()
        }
    }
    
    public func blockingStream(limit: Int = Int.max) throws -> [Feed] {
        return try self.list(page: 0, size: limit).toBlocking().toArray()
    }
    
    public func stream(limit: Int = Int.max) throws -> Observable<Feed> {
        return self.list(page: 0, size: limit)
    }
    
    public func blockingList(page: Int = 0, size: Int = 10) throws -> [Feed] {
        return try self.list(page: page, size: size).toBlocking().toArray()
    }

    public func list(page: Int = 0, size: Int = 10) -> Observable<Feed> {
        return Observable.create {
            obs in
            self.stream(page, size, obs)
            return Disposables.create()
        }.observeOn(MainScheduler.instance)
        .subscribeOn(MainScheduler.instance)
    }
    
    public func blockingSendWallPost(_ feedPost: FeedPost) throws -> Feed? {
        return try self.sendWallPost(feedPost).toBlocking().last()
    }
    
    public func sendWallPost(_ feedPost: FeedPost) -> Observable<Feed> {
        return Observable.create {
            obs in
            let _ = self.session.account.get().subscribe {
                e in
                if let e = e.element {
                    let _ = e.sendWallPost(feedPost).subscribe {
                        e in
                        if let e = e.element {
                            obs.onNext(e)
                        } else if let e = e.error {
                            obs.onError(e)
                        } else {
                            obs.onCompleted()
                        }
                    }
                } else {
                    obs.onCompleted()
                }
            }
            return Disposables.create()
        }.observeOn(MainScheduler.instance)
        .subscribeOn(MainScheduler.instance)
    }

    public func blockingSearch(_ search: Search, page: Int = 0, size: Int = 10) throws -> SearchResultValue<Feed>? {
        return try self.search(search, page: page, size: size).toBlocking().first()
    }
    
    public func search(_ search: Search, page: Int = 0, size: Int = 10) -> Observable<SearchResultValue<Feed>> {
        return Observable.create {
            obs in
            if size > 0 {
                let _ = self.session.clientService.search.get(page, size: size, params: search.toQueryParams()).subscribe {
                    e in
                    if let e = e.element?.resultsByType?.feeds {
                        obs.onNext(e)
                    } else if let e = e.error {
                        obs.onError(e)
                    } else {
                        let e = SearchResultValue<Feed>()
                        e.matchedCount = 0
                        obs.onNext(e)
                    }
                }
            } else {
                let e = SearchResultValue<Feed>()
                e.matchedCount = 0
                obs.onNext(e)
            }
            return Disposables.create()
            }.observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
    }
    
    public class Search: ISearch {
        
        public class Builder {
            private var user = User()
            private var mTextToSearch: String? = nil
            private var mSortOrder: SortOrder? = nil
            private var mLocationMaximumDistance: Double? = nil
            
            public init() {}
            
            public func setTextToSearch(_ textToSearch: String) -> Builder {
                self.mTextToSearch = textToSearch
                return self
            }
            
            public func setOrder(_ sortOrder: SortOrder) -> Builder {
                self.mSortOrder = sortOrder
                return self
            }
            
            public func setOwnerFirstName(_ firstName: String) -> Builder {
                self.user.firstName = firstName
                return self
            }
            
            public func setOwnerLastName(_ lastName: String) -> Builder {
                self.user.lastName = lastName
                return self
            }
            
            public func setLocation(_ location: Location) -> Builder {
                self.user.livingLocation = location
                return self
            }
            
            public func setOwnerLivingLocationMaximumDistanceInMeters(_ maximumDistance: Double) -> Builder {
                self.mLocationMaximumDistance = maximumDistance
                return self
            }
            
            public func setOwnerLivingLocationMaximumDistanceInKilometers(_ maximumDistance: Double) -> Builder {
                self.mLocationMaximumDistance = maximumDistance * 1000
                return self
            }
            
            public func build() -> Search {
                return Search(SearchQuery(user: user, q: mTextToSearch, name: nil, content: nil, maximumDistanceInMeters: mLocationMaximumDistance, sortOrder: mSortOrder, startDate: nil, endDate: nil, dateField: nil))
            }
        }
        
        override func toQueryParams() -> [String: String] {
            var m = super.toQueryParams()
            m["type"] = "FEED"
            return m
        }
    }
}
