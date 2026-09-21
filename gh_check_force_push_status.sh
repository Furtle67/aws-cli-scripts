#!/bin/bash
# Loop through all repos in an org and disable force push on main/master
#test to check FORCE push status  (should be disabled)
ORG="Furtle67"
BRANCH="main"  # or "master"

# Get all repos in the org
repos=$(gh repo list $ORG --limit 1000 --json name -q '.[].name')

for repo in $repos; do
  echo "Updating branch protection for: $repo"
  gh api /repos/$ORG/$repo/branches/$BRANCH/protection   | jq '.allow_force_pushes'
done

# Returns: true (bad) or false (good) or null (not set = not protected)
