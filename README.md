# Integrate the Atar iOS SDK

The guide below will walk you through the steps to integrate the Atar iOS SDK into your app, in order to start showing offers to your users.

## Step 1: Create an account and get your App Key

If you haven't already, create an account on the [Atar Dashboard](https://app.atargrowth.com/). Once you've created an account, you'll be able to create an app and get your App Key from the [settings page](https://app.atargrowth.com/settings).

## Step 2: Add the Atar iOS SDK to your app

The Atar SDK can be accessed via Swift package manager.

### 2.1 Find the package on Swift Package Manager

To add the package via Swift Package Manager

1. Select <b>Your Project</b>
2. Go to the tab <b>Package Dependencies</b>
3. Click the <b>+</b> button
4. Enter the package URL `https://github.com/Atar-Growth/Atar-iOS-SDK`

### 2.1 Add Atar

You should select <b>Atar</b> from the All Sources, and select <i>Up To Next Major Version</i>. Then click <b>Add Package</b>.

### 2.3 Verify that Atar is added as a dependency

You can verify that Atar has been successfully added by:

1. Select <b>Your App Target</b>
2. Go to the <b>General</b> tab
3. Scroll down to <b>Frameworks, Libraries, and Embedded Content</b>
4. Verify that you see <b>Atar</b>

## Step 3: Initialize the Atar SDK

Import the library in your **AppDelegate** class.

#### Swift

``` swift
import Atar
```

#### Objective C

``` objc
#import "Atar-Swift.h"
```

Initialize the Atar SDK in your **AppDelegate** class's **didFinishLaunchingWithOptions** method.

#### Swift

``` swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    Atar.getInstance().didFinishLaunching(appKey: "YOUR APP KEY")
    // your other code
    return true
}
```

#### Objective C

``` objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[Atar getInstance] didFinishLaunchingWithAppKey:@"YOUR APP KEY"];
    // your other code
    return YES;
}
```

Replace **YOUR APP KEY** with the App Key you got from the Atar Dashboard.

## Step 4: Show Offers after the user has completed a transaction

Once you've initialized the Atar SDK, you can show offers to your users. Here's an example of how you can show an interstitial offer after the user has completed a transaction.

#### Swift

```swift
let request = OfferRequest()
request.onPopupShown = { success, error in
    print("onPopupShown: \(success), \(error ?? "no error")")
}
request.onPopupCanceled = {
    print("onPopupCanceled")
}
request.onClicked = {
    print("onClicked")
}

// required
request.event = "purchase"
request.userId = "userId5678"
request.referenceId = "123456" // this is some unique reference ID for the transaction

// recommended
request.email = "user1234@email.com";
request.phone = "1234567890";

request.firstName = "Alex"
request.lastName = "Austin"
request.address1 = "123 Example St"
request.address2 = "Suite 123"
request.city = "Big City"
request.state = "ST"
request.zip = "12345"
request.country = "US"
request.amount = 29.98

Atar.getInstance().showOfferPopup(request: request)
```

#### Objective C

```objc
OfferRequest *request = [[OfferRequest alloc] init];
request.onPopupShown = ^(BOOL success, NSString * _Nullable error) {
    NSLog(@"onPopupShown: %d, %@", success, error);
};
request.onPopupCanceled = ^{
    NSLog(@"onPopupCanceled");
};
request.onClicked = ^{
    NSLog(@"onClicked");
};

// required
request.event = @"purchase";
request.userId = @"userId5678";
request.referenceId = @"123456"; // this is some unique reference ID for the transaction

// recommended
request.email = @"user1234@email.com";
request.phone = @"1234567890";

request.firstName = @"Alex";
request.lastName = @"Austin";
request.address1 = @"123 Example St";
request.address2 = @"Suite 123";
request.city = @"Big City";
request.state = @"ST";
request.zip = @"12345";
request.country = @"US";
request.amount = 29.98;

[[Atar getInstance] showOfferPopupWithRequest:request];
```

Replace the values in the **OfferRequest** object with the appropriate values for your user and transaction. Below you can find the full documented list of fields you can use in the **OfferRequest** object.

Note that the callback is optional and purely in case you would like to tie any additional functionality to the presentation of the offer.

### Offer Request Object Fields

| Req. | Field name  | Description                                    | Data type |
|------|-------------|------------------------------------------------|-----------|
| Req  | event       | User event that preceded the offers            | string    |
| Req  | referenceId | Some ID for reference for deduplication.       | string    |
| Req  | userId      | Some ID for the user.                          | string    |
| Rec  | email       | User email.                                    | string    |
| Rec  | phone       | User phone number.                             | string    |
| Rec  | gender      | User gender: M/F                               | string    |
| Rec  | dob         | Date of birth, YYYYMMDD                        | string    |
| Rec  | firstName   | User first name                                | string    |
| Rec  | lastName    | User last name                                 | string    |
| Opt  | amount      | Transaction amount                             | string    |
| Opt  | quantity    | Quantity of items purchased                    | int       |
| Opt  | paymentType | credit, PayPal, or other                       | string    |
| Opt  | address1    | Street address line 1                          | string    |
| Opt  | address2    | Street address line 2                          | string    |
| Opt  | city        | City                                           | string    |
| Opt  | state       | State                                          | string    |
| Opt  | country     | Country                                        | string    |

## Step 5: Trigger offer messages on user action

You can also trigger offer message on user actions. Here's an example of how you can trigger an offer message.

=== "Swift"
    ```swift
    let request = OfferRequest()
    request.onPopupShown = { success, error in
        print("onPopupShown: \(success), \(error ?? "no error")")
    }
    request.onPopupCanceled = {
        print("onPopupCanceled")
    }
    request.onClicked = {
        print("onClicked")
    }
    request.event = "level_completed"
    request.referenceId = UUID().uuidString
    request.userId = "userId1234"
    
    Atar.getInstance().showOfferMessage(request: request)
    ```

=== "Objective C"
    ```objc
    OfferRequest *request = [[OfferRequest alloc] init];
    request.onPopupShown = ^(BOOL success, NSString * _Nullable error) {
        NSLog(@"onPopupShown: %d, %@", success, error);
    };
    request.onPopupCanceled = ^{
        NSLog(@"onPopupCanceled");
    };
    request.onClicked = ^{
        NSLog(@"onClicked");
    };
    request.event = @"level_completed";
    request.referenceId = [[NSUUID UUID] UUIDString];
    request.userId = @"userId1234";
    
    [[Atar getInstance] showOfferMessageWithRequest:request];
    ```

## Step 6: Enable or disable the post session notification

You have full control over whether post session notifications are enabled or disabled. By default, post session notifications are disabled, so you would have to have previously enabled it.

### Disable post session notifications globally

You can head to the [dashboard settings](https://app.atargrowth.com/settings) and disable post session notifications globally. This will disable post session notifications for all users.

### Disable post session notifications for a specific user

To disable for a specific user, you can use the following method in the SDK whenever. This is persisted in user defaults and will be remembered for the user.

=== "Swift"
    ```swift
    Atar.getInstance().setPostSessionNotifDisabled(disabled: true)
    ```

=== "Objective C"
    ```objc
    [[Atar getInstance] setPostSessionNotifDisabledWithDisabled:YES];
    ```

## Step 7: Enable or disable the mid session message popup

You have full control over whether mid session message are enabled or disabled. By default, mid session message are disabled, so you would have to have previously enabled it.

### Disable mid session message globally

You can head to the [dashboard settings](https://app.atargrowth.com/settings) and disable mid session message globally. This will disable mid session message for all users.

### Disable mid session message for a specific user

To disable for a specific user, you can use the following method in the SDK whenever. This is persisted in user defaults and will be remembered for the user.

=== "Swift"
    ```swift
    Atar.getInstance().setMidSessionMessageDisabled(disabled: true)
    ```

=== "Objective C"
    ```objc
    [[Atar getInstance] setMidSessionMessageDisabled:YES];
    ```

## Need help?

If you have any questions or need help, please contact us at [support@atargrowth.com](mailto:support@atargrowth.com).
