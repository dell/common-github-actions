import requests
import re
import os
from github import Github

def get_latest_version(repo):
    # GitHub API URL for the latest release
    api_url = f"https://api.github.com/repos/kubernetes-csi/{repo}/releases/latest"

    # Get the JSON response from the API
    response = requests.get(api_url)
    release_data = response.json()  

    # Extract the latest version tag
    latest_version = release_data['tag_name']
    
    return latest_version

def update_config_file(repo, config_repo, config_file_path, github_token):
    # Get the latest version of the repository
    latest_version = get_latest_version(repo)

    # Authenticate with GitHub
    g = Github(github_token)
    repo = g.get_repo(config_repo)

    # Get the config file content
    contents = repo.get_contents(config_file_path)
    config_content = contents.decoded_content.decode()

    # Replace the version in the config file (assuming the version is specified as 'version: x.x.x')
    updated_config_content = re.sub(r'version: [\d.]+', f'version: {latest_version}', config_content)

    # Update the config file in the repository
    repo.update_file(config_file_path, "Update version", updated_config_content, contents.sha)

    print(f"The config file has been updated with the latest version of {repo}: {latest_version}")

if __name__ == "__main__":
    repo = os.getenv('INPUT_REPO')
    config_repo = os.getenv('INPUT_CONFIG_REPO')
    config_file_path = os.getenv('INPUT_CONFIG_FILE_PATH')
    github_token = os.getenv('INPUT_GITHUB_TOKEN')

    update_config_file(repo, config_repo, config_file_path, github_token)
