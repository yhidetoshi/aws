EC2_ID="$2"
aws ec2 start-instances --region ap-northeast-1 --instance-ids ${EC2_ID}
