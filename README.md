# postgres_benchmark
Repository for maintaining the benchmark for Postgres

## tpcb_benchmark_m5d_metal
tpcb_benchmark_m5d_metal is for performing benchmark on AWS instance type m5d.metal

### Assumptions/Pre-requisite

To run this benchmark, make sure have met the following criteria:

1. Provision m5d.metal instance with CentOS 8 x86_64

    https://docs.aws.amazon.com/quickstarts/latest/vmlaunch/welcome.html
    
2. Add three volumes of the following type:
    * volume_type: io2, Provisioned IOPs: 40000, Name: pg_data
    * volume_type: io2, Provisioned IOPs: 20000, Name: pg_indexes
    * volume_type: io2, Provisioned IOPs: 10000, Name: pg_wal
    
    For creating volumes, please refer to the following link:
    
    https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-creating-volume.html
   
3. Attach the volumes to the instance created. The following link gives information on how to attach a provisioned volumes:

   https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-attaching-volume.html

4. After attaching the volume, use the following commands to make it available for use. The following link can be used for making it available on VM:

   https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html
   
   Please make sure you have mounted the respective volumes to the following directories
   ```sudo mkdir -p /pg_data /pg_indexes /pg_wal
   chown <postgres user>:<postgres user> /pg_data /pg_indexes /pg_wal
   chmod 700 /pg_data /pg_indexes /pg_wal
   ```
 
  Examples of mounting volumes to the respective directory is given below:
   ```
   mount /dev/nvme7n1 /pg_data
   mount /dev/nvme6n1 /pg_wal
   mount /dev/nvme5n1 /pg_indexes
   ```
5. Install the PostgreSQL/EPAS specific version of binaries. For more information on installing PostgreSQL/EPAS, please refer to the PostgreSQL or EDB website.
6. Install the `at` and `git` packages on the RHEL.
 
### Installation steps for tpcb_benchmark_m5d_metal
1. Clone the repository using the git command on the `m5d.metal` instance using the following command:

    git clone https://github.com/vibhorkum/postgres_benchmark

 
### Usage and configuration for running the benchmark for a specific version of PostgreSQL/EPAS.

 `edb_env.sh` file inside the `tpcb_benchmark_m5d_metal` directory contains all the environment variables.
 For running the benchmark for a specific version, please modify the following using your favorite editor:
 ```
 PGBIN=/usr/pgsql-12/bin
PGUSER="postgres"
PGOWNER="postgres"
PGPORT=5432
PGDATABASE=postgres
PGHOST=/tmp
```

After modifying the file, run the following command:
```
cd postgres_benchmark/tpcb_benchmark_m5d_metal
./main.sh
```

### Benchmark results

`tpcb_benchmark_m5d_metal` keeps the consolidated results of all runs of the benchmark in `postgres_benchmark/tpcb_benchmark_m5d_metal/log/consolidated_tps.txt`
This is a CSV. You can use the excel/google sheet to analyze or plot a graph using the results.

For analyzing or plotting the graph, it is recommended to take the `average` or `median` of each TPS based on the number of connections.
The sample result of the `consolidated_tps.txt` file is given below:
```
connections,RUN: 1(tps),RUN: 2(tps),RUN: 3(tps)
1,803.959791,792.497908,797.139589
16,8694.290789,8615.502609,8671.770535
32,15479.738718,15471.298318,15483.024795
64,27685.198173,27563.961374,27624.810339
128,48062.894395,47811.986569,47531.853078
256,62411.832806,60984.958269,58934.647526
512,65300.560351,64930.024937,68794.695218
550,65968.196023,66199.315905,67655.082280
600,65502.238015,66213.076733,66517.615646
```
