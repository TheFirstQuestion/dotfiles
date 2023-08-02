# Output format: 2023-07-28_p12-48
timestamp() {
  now=$(date +"%Y-%m-%d_%P%I-%M")

  # Remove 'm' from the string
  output_string="${now//m/}"

  echo "$output_string"
  return 0
}

# Output format: 2023-07-28
datestamp() {
  now=$(date +"%Y-%m-%d")

  echo "$now"
  return 0
}
