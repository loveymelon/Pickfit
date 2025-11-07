# ReactorKit run() Extension 정리

## ⚡ run()과 Send의 역할 & 작동 원리

---

## 🎯 1. run()의 역할

### 역할
async/await를 ReactorKit의 Observable로 변환

### 작동 원리 (3단계)

```swift
func run(operation: ..., onError: ...) -> Observable<Mutation> {
    Observable.create { observer in              // 1️⃣ Observable 생성
        let task = Task {                        // 2️⃣ Task 시작
            let send = Send { observer.onNext($0) }
            try await operation(send)            // 3️⃣ 비즈니스 로직 실행
            observer.onCompleted()
        }
        return Disposables.create { task.cancel() }  // 4️⃣ 취소 관리
    }
}
```

### 흐름
```
async/await 코드
    ↓ run()
Observable<Mutation>
    ↓
Reactor.reduce()
    ↓
UI 업데이트
```

---

## 🎯 2. Send의 역할

### 역할
Mutation을 전달하면서 Task 취소 여부를 자동 체크

### 작동 원리

```swift
public struct Send<Mutation> {
    let send: (Mutation) -> Void  // observer.onNext 저장

    func callAsFunction(_ mutation: Mutation) {
        guard !Task.isCancelled else { return }  // ✅ 취소 체크
        self.send(mutation)  // observer.onNext(mutation) 호출
    }
}
```

### 사용
```swift
send(.setLoading(true))
// ↓ callAsFunction 자동 호출
// ↓ Task 취소 체크
// ↓ observer.onNext(.setLoading(true))
// ↓ reduce() → UI 업데이트
```

---

## 🔄 전체 흐름 (간단 버전)

```
[Reactor]
return run(
    operation: { send in
        send(.setLoading(true))        // 1️⃣
        let data = try await fetch()   // 2️⃣
        send(.setData(data))           // 3️⃣
    }
)
    ↓
[run() 내부]
Observable.create { observer in
    Task {
        let send = Send { observer.onNext($0) }
        try await operation(send)
        observer.onCompleted()
    }
}
    ↓
[send 호출 시]
callAsFunction 실행
→ guard !Task.isCancelled ✅
→ observer.onNext(.mutation)
→ reduce()
→ UI 업데이트
    ↓
[화면 이탈 시]
Disposables.create { task.cancel() }
→ Task.isCancelled = true
→ 이후 send() 호출 시 무시됨
```

---

## 🎤 면접 답변

### 질문 1: "run()은 무엇이고 왜 만들었나요?"

**답변**:
> "run()은 **async/await를 ReactorKit의 Observable로 변환**하는 Extension입니다.
>
> Repository는 순수하게 `async throws`로 데이터만 반환하고, Reactor에서 run()을 사용해서 Observable로 변환합니다.
>
> 이렇게 하면 **데이터 계층은 RxSwift에 의존하지 않고**, **Presentation 계층에서만 ReactorKit 패턴을 적용**할 수 있습니다.
>
> 또한 **Task 자동 취소**와 **onCompleted 자동 처리**로 메모리 안전성도 보장합니다."

---

### 질문 2: "run()이 내부적으로 어떻게 동작하나요?"

**답변**:
> "3단계로 동작합니다.
>
> **1. Observable.create 안에 Task를 생성**해서 async 작업을 시작합니다.
>
> **2. Send 구조체로 Mutation을 전달**하는데, callAsFunction이 Task 취소 여부를 자동 체크합니다.
>
> **3. Disposables.create로 화면 이탈 시 task.cancel()을 호출**해서 실행 중인 작업을 안전하게 종료합니다.
>
> 핵심은 **RxSwift Observable과 Swift Concurrency Task를 연결**하면서 **생명주기를 자동 관리**한다는 점입니다."

---

### 질문 3: "Send 구조체는 무슨 역할을 하나요?"

**답변**:
> "Send는 **Mutation 전달과 Task 취소 확인을 자동화**합니다.
>
> callAsFunction 덕분에 `send(.mutation)` 형태로 간결하게 호출하면, 내부에서 `guard !Task.isCancelled`로 취소 여부를 체크합니다.
>
> 만약 화면이 이미 사라진 상태라면 Mutation을 발생시키지 않고 return해서, 이미 해제된 객체에 접근하는 것을 방지합니다."

---

### 질문 4: "run() 대신 Repository에서 Observable을 반환하면 안 되나요?"

**답변**:
> "기술적으로는 가능하지만, **관심사의 분리** 측면에서 바람직하지 않습니다.
>
> Repository가 Observable을 반환하면 **데이터 계층이 RxSwift에 의존**하게 되고, 나중에 Combine으로 바꾸거나 SwiftUI로 마이그레이션할 때 Repository까지 모두 수정해야 합니다.
>
> 반면 Repository는 순수하게 `async throws`로 반환하고, Reactor에서만 run()으로 변환하면:
> - Repository는 프레임워크에 독립적
> - Presentation 로직과 데이터 로직 분리
> - 테스트 시 RxTest 불필요
>
> **계층별 책임을 명확히 분리**하는 것이 장기적으로 유지보수에 유리하다고 판단했습니다."

---

## 📋 핵심 요약 카드

### run()
- **역할**: async/await → Observable 변환
- **장점**: 보일러플레이트 제거, Task 자동 취소, 계층 분리

### Send
- **역할**: Mutation 전달 + Task 취소 체크
- **방법**: callAsFunction으로 `send(.mutation)` 문법 제공

### 작동 원리
1. Observable.create → Task 생성
2. Send → observer.onNext + 취소 체크
3. Disposables.create → task.cancel()

---

## 💡 run() Extension의 장점 (완전판)

1. ✅ **보일러플레이트 제거** (코드 간결함)
   - 35줄 → 18줄 (-48%)
   - Observable.create, do-catch, onCompleted 반복 제거

2. ✅ **onCompleted 자동** (실수 방지)
   - 까먹을 수 없는 구조
   - 성공/실패 관계없이 자동 처리

3. ✅ **Task 자동 취소** (메모리 안전성)
   - Disposables.create { task.cancel() }
   - 화면 이탈 시 자동 종료

4. ✅ **취소 상태 확인** (안전한 Mutation)
   - guard !Task.isCancelled
   - 이미 해제된 객체 접근 방지

5. ✅ **async/await 활용** (가독성)
   - async let으로 병렬 호출
   - if/guard 조건부 로직

6. ✅ **계층 분리** (설계 원칙)
   - Repository는 순수 async/await
   - Reactor에서만 ReactorKit 적용

---

## 🆚 비교: Extension 없이 직접 구현 vs run() 사용

### Extension 없이 (35줄)
```swift
case .viewIsAppearing:
    return Observable<Mutation>.create { observer in
        let task = Task {
            do {
                observer.onNext(.setLoading(true))

                async let stores = self.storeRepository.fetchStores(...)
                async let banners = self.storeRepository.fetchBanners()
                let (s, b) = try await (stores, banners)

                observer.onNext(.setStores(...))

                if !s.stores.isEmpty {
                    let detail = try await self.storeRepository.fetchStoreDetail(...)
                    observer.onNext(.setMenuList(...))
                }

                observer.onNext(.setBanners(b))
                observer.onCompleted()  // 까먹으면 버그!

            } catch {
                observer.onNext(.setError(error))
                observer.onCompleted()  // 여기도!
            }
        }
        return Disposables.create { task.cancel() }
    }
```

### run() 사용 (18줄)
```swift
case .viewIsAppearing:
    return run(
        operation: { send in
            send(.setLoading(true))

            async let stores = self.storeRepository.fetchStores(...)
            async let banners = self.storeRepository.fetchBanners()
            let (s, b) = try await (stores, banners)

            send(.setStores(...))

            if !s.stores.isEmpty {
                let detail = try await self.storeRepository.fetchStoreDetail(...)
                send(.setMenuList(...))
            }

            send(.setBanners(b))
        },
        onError: { .setError($0) }
    )
```

**차이점**:
- 코드 라인: 35줄 → 18줄 (-48%)
- 보일러플레이트: 17줄 → 2줄
- onCompleted 실수: 가능 → 불가능
- 가독성: 낮음 → 높음

---

## 🔍 실제 사용 예시 (HomeReactor)

**파일**: `Pickfit/Presentation/Home/HomeReactor.swift:57-95`

```swift
case .viewIsAppearing:
    return run(
        operation: { [weak self] send in
            guard let self else { return }

            send(.setLoading(true))

            // 위치 정보 가져오기
            let location = await LocationManager.shared.getCurrentLocation()

            // 병렬 API 호출
            async let storesResult = self.storeRepository.fetchStores(
                category: "Modern",
                longitude: location.longitude,
                latitude: location.latitude,
                orderBy: .distance
            )
            async let bannersResponse = self.storeRepository.fetchBanners()

            let (stores, banners) = try await (storesResult, bannersResponse)

            send(.setStores(stores: stores.stores, nextCursor: stores.nextCursor))

            // 첫 번째 브랜드의 메뉴 로드 (조건부)
            if !stores.stores.isEmpty {
                let storeDetail = try await self.storeRepository.fetchStoreDetail(
                    storeId: stores.stores[0].storeId
                )
                send(.setMenuList(storeDetail.menuList))
                send(.setSelectedBrandIndex(0))
            }

            send(.setBanners(banners))
        },
        onError: { error in
            print("❌ [API] HomeReactor error: \(error.localizedDescription)")
            return .setError(error)
        }
    )
```

**특징**:
- ✅ 병렬 API 호출 (stores + banners 동시)
- ✅ 조건부 로직 (stores가 있으면 detail 추가 호출)
- ✅ 순차적 Mutation (setStores → setMenuList → setBanners)
- ✅ 에러 처리 간결함

---

## 📊 계층별 책임 분리

```
┌─────────────────────────────────────────┐
│ NetworkManager & Repository             │
│ → "데이터를 가져오는 것"에만 집중       │
│ → 순수한 async/await                    │
│ → RxSwift 의존성 없음                   │
└─────────────────────────────────────────┘
              ↓ async throws Entity
┌─────────────────────────────────────────┐
│ run() Extension                          │
│ → async/await ↔ Observable 변환         │
│ → Task 생명주기 관리                    │
└─────────────────────────────────────────┘
              ↓ Observable<Mutation>
┌─────────────────────────────────────────┐
│ Reactor                                  │
│ → "비즈니스 로직"에만 집중              │
│ → UI 상태 관리, 흐름 제어               │
│ → ReactorKit 패턴 적용                  │
└─────────────────────────────────────────┘
```

**이점**:
- Repository는 프레임워크에 독립적
- 나중에 Combine/SwiftUI 마이그레이션 시 Repository 재사용 가능
- 테스트 시 RxTest 불필요
- 계층별 책임 명확
