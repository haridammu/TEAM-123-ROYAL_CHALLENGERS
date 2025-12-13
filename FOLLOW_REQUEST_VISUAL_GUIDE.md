# Follow Request System - Visual Guide

## 🔄 Complete Follow Request Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        FOLLOW REQUEST WORKFLOW                          │
└─────────────────────────────────────────────────────────────────────────┘

1. USER A INITIATES FOLLOW
   ↓
   User A clicks "Follow" on User B's private profile
   ↓
   POST /follow-request
   {
     requesterId: "UUID_A",
     targetUserId: "UUID_B"
   }

2. BACKEND CREATES REQUEST
   ↓
   INSERT INTO connections (
     requester_id: "UUID_A",
     receiver_id: "UUID_B",    ← KEY: This is receiver, not sender
     status: "pending"          ← KEY: Must be PENDING not ACCEPTED
   )

3. DATABASE STATE
   ┌──────┬──────────┬──────────┬─────────┐
   │  id  │requester │ receiver │ status  │
   ├──────┼──────────┼──────────┼─────────┤
   │ 100  │ UUID_A   │ UUID_B   │pending  │  ← User A's request to follow B
   └──────┴──────────┴──────────┴─────────┘

4. USER B SEES NOTIFICATION
   ↓
   GET /pending-requests?userId=UUID_B
   ↓
   Query: WHERE receiver_id = UUID_B AND status = 'pending'
   ↓
   Result:
   [
     {
       id: 100,
       requesterId: "UUID_A",
       targetUserId: "UUID_B",
       status: "pending"
     }
   ]

5. USER B ACCEPTS REQUEST
   ↓
   POST /accept-request
   {
     requestId: 100
   }
   ↓
   UPDATE connections 
   SET status = 'accepted' 
   WHERE id = 100

6. DATABASE STATE AFTER ACCEPTANCE
   ┌──────┬──────────┬──────────┬──────────┐
   │  id  │requester │ receiver │ status   │
   ├──────┼──────────┼──────────┼──────────┤
   │ 100  │ UUID_A   │ UUID_B   │accepted  │  ← Now they follow each other
   └──────┴──────────┴──────────┴──────────┘

7. USER A CAN NOW VIEW USER B'S POSTS
   ↓
   User A and User B are now connected
```

---

## 🔑 Key Points

### 1. **REQUESTER vs RECEIVER**
```
When User A follows User B (who has a private account):

User A = REQUESTER (the one requesting)
User B = RECEIVER (the one receiving the request)

INSERT INTO connections:
  requester_id: User A's ID  ← Who wants to follow
  receiver_id: User B's ID   ← Who is being requested to follow
```

### 2. **STATUS TRANSITIONS**
```
       pending          accepted
           ↓               ↓
Create → PENDING ────→ ACCEPTED ─→ Can view posts
           ↓
           rejected
           ↓
         REJECTED ──────→ Can retry (deletes old, creates new)
```

### 3. **CRITICAL: Query Uses receiver_id**
```
DON'T:  WHERE target_user_id = ? AND status = 'pending'
DON'T:  WHERE followed_id = ? AND status = 'pending'

DO:     WHERE receiver_id = ? AND status = 'pending'  ✅
```

---

## 💾 Database Schema

```sql
connections TABLE:
┌─────────────┬──────────┬─────────────────────┐
│ Column      │ Type     │ Description         │
├─────────────┼──────────┼─────────────────────┤
│ id          │ INT PK   │ Primary key         │
│ requester_id│ UUID     │ User who requested  │
│ receiver_id │ UUID     │ User being asked    │
│ status      │ TEXT     │ pending/accepted/   │
│             │          │ rejected            │
│ created_at  │ TIMESTAMP│ When created        │
│ updated_at  │ TIMESTAMP│ When last updated   │
└─────────────┴──────────┴─────────────────────┘
```

---

## 🎯 Service Method Flow

```
SocialService
    ↓
┌───────────────────────────────────────┐
│ createFollowRequest()                  │
├───────────────────────────────────────┤
│ 1. Check pending request exists?       │
│    └─→ Return existing if found        │
│                                        │
│ 2. Check accepted connection exists?   │
│    └─→ Return existing if found        │
│                                        │
│ 3. Check rejected request exists?      │
│    └─→ Delete old, create new          │
│                                        │
│ 4. Create NEW pending request          │
│    └─→ INSERT status='pending'         │
└───────────────────────────────────────┘
    ↓
SupabaseService.createFollowRequest()
    ↓
Database: INSERT connections
    ↓
Connection object returned with status='pending'
```

---

## 🔍 Query Examples

### Create Follow Request
```dart
// Before (WRONG - created as accepted):
await db.insert({
  requester_id: userId,
  receiver_id: targetId,
  status: 'accepted'  // ❌ WRONG!
});

// After (CORRECT - creates as pending):
await db.insert({
  requester_id: userId,
  receiver_id: targetId,
  status: 'pending'  // ✅ CORRECT!
});
```

### Get Pending Requests
```dart
// Before (WRONG - too many fallback checks):
try {
  result = query('receiver_id');
} catch {
  try {
    result = query('followed_id');
  } catch {
    result = query('target_user_id');
  }
}

// After (CORRECT - single clear query):
final result = await client
    .from('connections')
    .select()
    .eq('receiver_id', userId)
    .eq('status', 'pending');
```

---

## 🧪 Testing the Flow

### Test 1: Create Request
```
User A ID: b50bcdef-d22c-4d4a-b561-c53db7809232
User B ID: f12a2ce7-d6ac-4bcb-91ea-866e7c1d5acb

await socialService.createFollowRequest(
  requesterId: "b50bcdef...",
  targetUserId: "f12a2ce7..."
);

Expected:
✅ CREATE INSERT with status='pending'
✅ Database shows: pending request
✅ Logs show: "[FollowRequest] Follow request created..."
```

### Test 2: Get Pending Requests
```
await socialService.getPendingFollowRequests("f12a2ce7...");

Expected:
✅ SELECT WHERE receiver_id='f12a2ce7...' AND status='pending'
✅ Returns 1 request
✅ Logs show: "[GetPendingRequests] Found 1 pending requests"
```

### Test 3: Accept Request
```
await socialService.acceptFollowRequest(100);

Expected:
✅ UPDATE WHERE id=100 SET status='accepted'
✅ Connection becomes active
✅ User A can now view User B's posts
```

---

## ❌ Common Mistakes to Avoid

```
❌ WRONG:
  - Creating request with status='accepted'
  - Querying receiver_id but inserting target_user_id
  - Not checking for existing requests
  - Using wrong column name in WHERE clause
  - Returning all connections instead of just pending

✅ CORRECT:
  - Always create with status='pending'
  - Use receiver_id consistently everywhere
  - Check for existing PENDING request first
  - Always specify status='pending' in WHERE
  - Filter by status = 'pending' when fetching
```

---

## 📊 Logging Output (After Fix)

```
✅ Creating follow request:
[FollowRequest] Creating follow request from b50bcdef... to f12a2ce7...
[FollowRequest] No existing connection found, creating new follow request
[FollowRequest] Follow request created with ID: 100, Status: pending

✅ Fetching pending requests:
[GetPendingRequests] Fetching pending follow requests for user: f12a2ce7...
[GetPendingRequests] Found 1 pending requests
[GetPendingRequests] - Request ID: 100, From: b50bcdef..., Status: pending

✅ Getting pending count:
[PendingCount] Getting pending follow requests count for user: f12a2ce7...
[PendingCount] Found 1 pending follow requests for user: f12a2ce7...
```

---

## 🚨 Before vs After

### BEFORE (BROKEN)
```
User A follows User B
    ↓
INSERT connections (status='accepted')  ← WRONG!
    ↓
User B checks pending requests
    ↓
Query returns 0  ← No pending requests shown!
    ↓
User B doesn't see the request  ← BUG! 🐛
```

### AFTER (FIXED)
```
User A follows User B
    ↓
INSERT connections (status='pending')  ← CORRECT!
    ↓
User B checks pending requests
    ↓
Query returns 1 request  ← Found the pending request!
    ↓
User B sees the request  ← WORKS! ✅
```

---

## 🎉 Success Criteria

After the fix, you should see:

1. ✅ Follow request created with `status='pending'` (not 'accepted')
2. ✅ User receives notification when they get a request
3. ✅ Pending requests list shows 1+ items
4. ✅ Pending count shows correct number
5. ✅ Can accept/reject requests
6. ✅ After accepting, users can see each other's posts
7. ✅ Logs show proper debugging info with `[FollowRequest]` prefix

---

**Remember:** The key is that `status` must be created as `'pending'`, not `'accepted'`!
