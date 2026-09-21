


export AWS_REGION=us-east-1
export AWS_PROFILE=nphase


echo '"ListenerArn,LoadBalancerArn,Port,Protocol,SslPolicy' > lb_tls_audit.csv

aws elbv2 describe-load-balancers  --query 'LoadBalancers[?Scheme==`internet-facing`].LoadBalancerArn'  --output text | tr '\t' '\n' | while read arn; do
    # with only https
    # aws elbv2 describe-listeners --load-balancer-arn "$arn"       --output json       --query "Listeners[?Protocol=='HTTPS']" |     jq -r --arg arn "$arn" '.[] | [$arn, (.Port|tostring), .SslPolicy] | @csv'
    # 
    # all:
    aws --profile nphase elbv2 describe-listeners --load-balancer-arn $arn   | jq -rs '.[]|.Listeners[]|."ListenerArn"+","+."LoadBalancerArn"+","+(."Port"|tostring)+","+"Protocol"+","+(."SslPolicy" // "none")'

done >> lb_tls_audit.csv


#aws --profile nphase elbv2 describe-load-balancers   --query 'LoadBalancers[?Scheme==`internet-facing`].LoadBalancerArn'   --output text | tr '\t' '\n' | while read arn; do
#   aws --profile nphase elbv2 describe-listeners --load-balancer-arn "$arn"  --query "Listeners[?Protocol=='HTTPS'].[LoadBalancerArn,Port,SslPolicy]"  --output table
#done

