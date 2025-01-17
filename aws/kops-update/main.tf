resource "null_resource" "kops-update" {
  triggers = var.triggers

  provisioner "local-exec" {
    command = <<EOF
      ${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} \
        update cluster ${var.cluster-name} --yes

      ${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} \
        export kubecfg ${var.cluster-name} --admin

      until ${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} \
        validate cluster --name ${var.cluster-name}
      do
        echo "Cluster isn't available yet"
        sleep 10s
      done

      KOPS_FEATURE_FLAGS="+DrainAndValidateRollingUpdate" \
      ${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} \
        rolling-update cluster ${var.cluster-name} \
        ${var.rolling-update == "true" ? "--yes" : ""}
EOF
  }
}
