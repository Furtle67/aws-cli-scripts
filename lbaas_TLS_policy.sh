
#  code to gather data for FedRAMP control IA05 
#  

export AWS_REGION=us-east-1
export AWS_PROFILE=nphase


echo '"ListenerArn,LoadBalancerArn,Port,Protocol,SslPolicy' > ia_05_LBaaS_TLS_Audit.csv

aws elbv2 describe-load-balancers  --query 'LoadBalancers[?Scheme==`internet-facing`].LoadBalancerArn'  --output text | tr '\t' '\n' | while read arn; do
    # with only https
    # aws elbv2 describe-listeners --load-balancer-arn "$arn"       --output json       --query "Listeners[?Protocol=='HTTPS']" |     jq -r --arg arn "$arn" '.[] | [$arn, (.Port|tostring), .SslPolicy] | @csv'
    # 
    # all:
    aws --profile nphase elbv2 describe-listeners --load-balancer-arn $arn   | jq -rs '.[]|.Listeners[]|."ListenerArn"+","+."LoadBalancerArn"+","+(."Port"|tostring)+","+"Protocol"+","+(."SslPolicy" // "none")'

done >> ia_05_LBaaS_TLS_Audit.csv


#aws --profile nphase elbv2 describe-load-balancers   --query 'LoadBalancers[?Scheme==`internet-facing`].LoadBalancerArn'   --output text | tr '\t' '\n' | while read arn; do
#   aws --profile nphase elbv2 describe-listeners --load-balancer-arn "$arn"  --query "Listeners[?Protocol=='HTTPS'].[LoadBalancerArn,Port,SslPolicy]"  --output table
#done

