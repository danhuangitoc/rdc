resource "aws_cloudwatch_event_rule" "guardduty_findings_rule" {
  provider = aws.security
  name        = "guardduty_findings"
  description = "GuardDuty Findings Rule"

  event_pattern = jsonencode(
    {
        "source": [
            "aws.guardduty"
        ],
        "detail-type": [
            "GuardDuty Finding"
        ],
        "detail": {
             "severity": [
                4,
                4,
                4.1,
                4.2,
                4.3,
                4.4,
                4.5,
                4.6,
                4.7,
                4.8,
                4.9,
                5,
                5.1,
                5.2,
                5.3,
                5.4,
                5.5,
                5.6,
                5.7,
                5.8,
                5.9,
                6,
                6,
                6.1,
                6.2,
                6.3,
                6.4,
                6.5,
                6.6,
                6.7,
                6.8,
                6.9,
                7,
                7,
                7.1,
                7.2,
                7.3,
                7.4,
                7.5,
                7.6,
                7.7,
                7.8,
                7.9,
                8,
                8,
                8.1,
                8.2,
                8.3,
                8.4,
                8.5,
                8.6,
                8.7,
                8.8,
                8.9
            ] 
        }
    }
  )
}

resource "aws_cloudwatch_event_target" "gd_findings_sns" {
  provider = aws.security
  rule      = aws_cloudwatch_event_rule.guardduty_findings_rule.name
  target_id = "GuardDutyFindingsSNS"
  arn       = aws_sns_topic.guardduty_alerts.arn
}

resource "aws_sns_topic" "guardduty_alerts" {
  provider = aws.security
  name = "rd-sns-guardduty-alerts"
}

resource "aws_sns_topic_policy" "default" {
  provider = aws.security
  arn    = aws_sns_topic.guardduty_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.guardduty_alerts.arn]
  }
}

resource "aws_sns_topic_subscription" "guardduty_email_notification" {
  provider = aws.security
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "email"
  endpoint  = var.guardduty_notification_email
}