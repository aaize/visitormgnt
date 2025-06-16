# visitormgnt
A College Project to manage visitors.

<<workflow>>

START
  |
[Splash Screen]
  |
  |--> SharedPreferences.contains(username)?
         |
         |---> NO  ------------------> [Login Screen]
         |
         |---> YES
                |
                |---> if username == 'security' ---> [Security Camera Screen]
                |
                |---> else (e.g., MCA20308) -------> [Faculty Home Screen]

--------------------------------------
[Login Screen]
  |
  |--> Enter Username & Password
         |
         |---> if valid:
                  Save to SharedPreferences
                  |
                  |---> if username == 'security' --> [Security Camera Screen]
                  |
                  |---> else --> [Faculty Home Screen]
         |
         |---> else --> Show Error

--------------------------------------
[Security Camera Screen]
  |
  |---> Auto Capture Face
         |
         v
[Visitor Form Screen]
  |
  |---> Enter Visitor Details + Faculty Username
         |
         |---> On Submit:
                |
                |---> Save to Firestore ⁠ visitors ⁠ collection
                |---> Show Visitor Card (with Save/Share option)
  |
  |---> 🔔 Notification Icon (top-right)
         |
         |---> Opens Security Dashboard
                  |
                  |---> Shows list of visitors marked as:
                          - ✅ Visited
                          - ❌ Cancelled
                  |
                  |---> Helps track who has left or cancelled

--------------------------------------
[Faculty Home Screen]
  |
  |---> 🔔 Bell Icon with Badge Count
         |
         |---> On click: Show Visitor Cards for that faculty
                |
                |---> Each Card has:
                         [Cancel]  [Visited]
                |
                |---> On Action:
                        |
                        |---> Move data from ⁠ visitors ⁠ to:
                                - ⁠ visited ⁠ collection (if visited)
                                - ⁠ cancelled ⁠ collection (if cancelled)
                        |
                        |---> Delete from ⁠ visitors ⁠ collection
