# 1. Register collector
$register = Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8000/api/v1/auth/register" `
  -ContentType "application/json" `
  -Body '{"phone_number": "8888888888", "pin": "1234", "preferred_language": "Hindi", "display_name": "Test", "operating_district": "Mumbai", "operating_state": "Maharashtra"}'
$token = $register.access_token
Write-Host "--- Step 1: Register ---"
Write-Host "Token: $token"
Write-Host ""

# 2. Create a lot
$lot = Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8000/api/v1/lots/create" `
  -ContentType "application/json" `
  -Headers @{Authorization = "Bearer $token"} `
  -Body '{"material_category": "PCB", "approximate_weight": 3.5, "condition": "Mixed", "collection_location": {"lat": 19.0728, "lng": 73.0183}}'
$lotId = $lot.lot_id
Write-Host "--- Step 2: Create Lot ---"
Write-Host "Lot ID: $lotId"
Write-Host ($lot | ConvertTo-Json -Depth 5)
Write-Host ""

# 3. Fetch price board
$prices = Invoke-RestMethod `
  -Uri "http://localhost:8000/api/v1/prices/current?district=Mumbai&category=PCB" `
  -Headers @{Authorization = "Bearer $token"}
Write-Host "--- Step 3: Fetch Prices ---"
Write-Host ($prices | ConvertTo-Json -Depth 5)
Write-Host ""

# 4. Match recyclers
$recyclers = Invoke-RestMethod `
  -Uri "http://localhost:8000/api/v1/recyclers/match?lat=19.0728&lng=73.0183&category=PCB&radius_km=50" `
  -Headers @{Authorization = "Bearer $token"}
Write-Host "--- Step 4: Match Recyclers ---"
Write-Host ($recyclers | ConvertTo-Json -Depth 5)
Write-Host ""

$recyclerId = $recyclers[0].recycler_id

# 5. Create transaction
$tx = Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8000/api/v1/transactions/create" `
  -ContentType "application/json" `
  -Headers @{Authorization = "Bearer $token"} `
  -Body "{`"lot_id`": `"$lotId`", `"recycler_id`": `"$recyclerId`", `"quoted_price`": 210}"
$txId = $tx.transaction_id
Write-Host "--- Step 5: Create Transaction ---"
Write-Host "Transaction ID: $txId"
Write-Host ($tx | ConvertTo-Json -Depth 5)
Write-Host ""

# 6. Generate handover record
$handover = Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8000/api/v1/handover/$lotId/generate" `
  -Headers @{Authorization = "Bearer $token"}
$refNumber = $handover.ref_number
Write-Host "--- Step 6: Generate Handover ---"
Write-Host "Handover Ref: $refNumber"
Write-Host ($handover | ConvertTo-Json -Depth 5)
Write-Host ""

# 7. Verify handover publicly (no auth)
$verify = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/handover/$refNumber/verify"
Write-Host "--- Step 7: Verify Handover ---"
Write-Host ($verify | ConvertTo-Json -Depth 5)
Write-Host ""

# 8. Test sync pull
$sync = Invoke-RestMethod `
  -Uri "http://localhost:8000/api/v1/sync/pull?since=2024-01-01T00:00:00Z" `
  -Headers @{Authorization = "Bearer $token"}
Write-Host "--- Step 8: Sync Pull ---"
Write-Host ($sync | ConvertTo-Json -Depth 5)
Write-Host ""
