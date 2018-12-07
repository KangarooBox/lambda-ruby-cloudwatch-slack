require 'bundler'
Bundler.require(:default)

module LambdaFunctions
  class Handler
    def self.process(event:, context:)
      puts event
      data = event['Records'].first
      notifier = Slack::Notifier.new ENV["SLACK_WEBHOOK_URL"]

      message = ''
      timestamp = Time.now().to_i
      fields = [{title: 'Unprocessed Message', value: data.to_s, short: false}]
      color = 'warning'

      case data['EventSource']
      when 'aws:sns'
        case data['Sns']['Type']
        when 'Notification'
          subject = data['Sns']['Subject']
          message = JSON.parse(data['Sns']['Message'])
          region = data['EventSubscriptionArn'].split(':')[3]
          
          trigger = "#{message['Trigger']['Statistic']} #{message['MetricName']} "
          trigger += "#{message['Trigger']['ComparisonOperator']} "
          trigger += "#{message['Trigger']['Threshold']} for "
          trigger += "#{message['Trigger']['EvaluationPeriods']} period(s) of "
          trigger += "#{message['Trigger']['Period']} seconds."

          fields = [
            { title: 'Alarm Name', value: message['AlarmName'], short: true },
            { title: 'Alarm Description', value: message['AlarmReason'], short: false },
            { title: 'Trigger', value: trigger, short: false },
            { title: 'Old State', value: message['OldStateValue'], short: true },
            { title: 'Current State', value: message['NewStateValue'], short: true },
            { title: 'Link to alarm', 
              value: "https://console.aws.amazon.com/cloudwatch/home?region=#{region}#alarm:alarmFilter=ANY;name=#{URI.encode(message['AlarmName'])}",
              short: false
            }
          ]
          timestamp = Time.new(message['StateChangeTime']).to_i rescue 1
          color = message['NewStateValue'] == "ALARM" ? 'danger' : 'good'

        else
          subject = "Unknown SNS message Type"
        end
      else
        subject = "Unknown message format"
      end

      # Clean up the subject
      Slack::Notifier::Util::LinkFormatter.format(subject)

      # Build the attachment
      attachment = {
        text: "*#{subject}*",
        color: color,
        fields: fields,
        icon_emoji: ":aws:",
        ts: timestamp
      }
      
      # Post the message to Slack
      notifier.post attachments: [attachment]

      { statusCode: 200, body: event }
    end
  end
end