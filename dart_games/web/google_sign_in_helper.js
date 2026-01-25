// Helper to get Google ID Token using Google One Tap / Identity Services
window.googleSignInHelper = {
  // Sign in and get ID Token (JWT credential)
  async getIdToken(clientId) {
    return new Promise((resolve, reject) => {
      // Initialize Google Identity Services
      google.accounts.id.initialize({
        client_id: clientId,
        callback: (response) => {
          // response.credential contains the JWT ID token!
          if (response.credential) {
            console.log('Got ID Token from Google:', response.credential.substring(0, 50) + '...');
            resolve(response.credential);
          } else {
            reject(new Error('No credential received from Google'));
          }
        },
      });

      // Prompt the user to select an account
      google.accounts.id.prompt((notification) => {
        if (notification.isNotDisplayed() || notification.isSkippedMoment()) {
          // Prompt was not shown, show the button-based flow instead
          console.log('One Tap not available, using button flow');

          // Create a temporary button container
          const buttonDiv = document.createElement('div');
          buttonDiv.id = 'google_signin_button_temp';
          document.body.appendChild(buttonDiv);

          // Render the Google Sign-In button
          google.accounts.id.renderButton(
            buttonDiv,
            {
              theme: 'filled_blue',
              size: 'large',
              text: 'signin_with',
              shape: 'rectangular',
            }
          );

          // Click the button programmatically
          setTimeout(() => {
            buttonDiv.querySelector('[role="button"]').click();
          }, 100);
        }
      });
    });
  }
};
