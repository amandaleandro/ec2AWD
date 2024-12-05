 steps:
      - name: Checkout Code
        uses: actions/checkout@v2

      - name: Setup SSH
        uses: webfactory/ssh-agent@v0.5.3
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

      - name: Deploy Code via SSH
        run: |
          ssh -o StrictHostKeyChecking=no ec2-user@${{ steps.ec2info.outputs.instance_ip }} 'bash -s' < ./scripts/deploy.sh
  