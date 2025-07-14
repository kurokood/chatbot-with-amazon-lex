resource "aws_dynamodb_table" "meetings_table" {
  name           = "Meetings"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "meetingId"

  attribute {
    name = "meetingId"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "date"
    projection_type = "ALL"
  }
}