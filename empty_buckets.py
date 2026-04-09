import boto3


session=boto3.Session(profile_name='nphase', region_name='us-east-1')
s3 = session.client('s3')
response = s3.list_buckets()

empty_buckets = []
not_empty_buckets = []

for bucket in response['Buckets']:
 bucket_name = bucket['Name']
 response = s3.list_objects_v2(Bucket=bucket_name)
 if 'Contents' in response:
     total_size_bytes = sum([obj['Size'] for obj in response['Contents']])
     total_size_mb = total_size_bytes/1024
     print(bucket['Name'],total_size_mb)
     
     if total_size_bytes == 0:
         empty_buckets.append(bucket_name)
 else:
         empty_buckets.append(bucket_name) #no contents
   
#print(empty_buckets)


