
(use-package '(:local-time
	       :simple-date
	       :cl-interpol
	       :s-sql
	       :postmodern))

(named-readtables:in-readtable :interpol-syntax)

(postmodern:connect-toplevel "inventory-dev" "inventory-dev" "such_wow!" "192.168.0.8")

;;; Models
;;; ;;;;;;

(defclass location ()
  ((id :accessor id
       :col-type serial
       :initarg :id
       :initform nil)
   (created_at :reader created-at
	       :col-type timestamp
	       :initarg :created-at
               :initform (local-time:format-timestring nil (now) :format '(:year #\- :month #\- :day #\Space :hour #\: :min #\: :sec)))
   (name :initarg :name
	 :accessor location-name
	 :col-type (:varchar 128))
   (position :initarg :position
	     :accessor location-position
	     :col-type (:varchar 128)))
  (:metaclass postmodern:dao-class)
  (:keys id))

(deftable location
  (!dao-def))


(defclass user ()
  ((id :accessor id
       :col-type serial
       :initarg :id
       :initform nil)
   (created_at :reader created-at
	       :col-type timestamp
	       :initarg :created-at
               :initform (simple-date:universal-time-to-timestamp
                          (local-time:timestamp-to-universal
                           (local-time:now))))
   (username :initarg :username
	     :accessor user-username
	     :col-type (:varchar 64)))
  (:metaclass postmodern:dao-class)
  (:keys id))

(deftable user
  (!dao-def))


(defclass inventory ()
  ((id :accessor id
       :col-type serial
       :initarg :id
       :initform nil)
   (created_at :reader created-at
	       :col-type timestamp
	       :initarg :created-at
               :initform (simple-date:universal-time-to-timestamp
                          (local-time:timestamp-to-universal
                           (local-time:now))))
   (name :initarg :name
	 :accessor inventory-name
	 :col-type (:varchar 64))
   (user-id :initarg :user
	    :accessor inventory-user-id
	    :col-type integer))
  (:metaclass postmodern:dao-class)
  (:keys id))

(deftable inventory
  (!dao-def)
  (!foreign 'user 'user-id 'id :on-delete :cascade :on-update :cascade))


(defclass item ()
  ((id :accessor id
       :col-type serial
       :initarg :id
       :initform nil)
   (created_at :reader created-at
	       :col-type timestamp
	       :initarg :created-at
               :initform (simple-date:universal-time-to-timestamp
                          (local-time:timestamp-to-universal
                           (local-time:now))))
   (name :initarg :name
	 :accessor item-name
	 :col-type (:varchar 128))
   (brand :initarg :brand
	  :accessor item-brand
	  :col-type (:varchar 128))
   (notes :initarg :notes
	  :accessor :item-notes
	  :col-type (:text))
   (measure-unit :initarg :unit
		 :accessor item-measure-unit
		 :col-type (:varchar 32))
   (priority :initarg :priority
	     :accessor item-priority
	     :col-type (:integer)))
  (:metaclass postmodern:dao-class)
  (:keys id))

(deftable item
  (!dao-def))


(defclass depletion ()
  ((id :accessor id
       :col-type serial
       :initarg :id
       :initform nil)
   (created_at :reader created-at
	       :col-type timestamp
	       :initarg :created-at
               :initform (simple-date:universal-time-to-timestamp
                          (local-time:timestamp-to-universal
                           (local-time:now))))
   (quantity :initarg :quantity
		  :accessor depletion-quantity
		  :col-type integer)
   (item-id  :initarg :item
	     :accessor depletion-item-id
	     :col-type integer)
   (inventory-id :initarg :inventory
		 :accessor depletion-inventory-id
		 :col-type integer))
  (:metaclass postmodern:dao-class)
  (:keys id))

(deftable depletion
  (!dao-def)
  (!foreign 'item 'item-id 'id :on-delete :cascade :on-update :cascade)
  (!foreign 'inventory 'inventory-id 'id :on-delete :cascade :on-update :cascade))


(defclass acquisition ()
  ((id :accessor id
       :col-type serial
       :initarg :id
       :initform nil)
   (created_at :reader created-at
	       :col-type timestamp
	       :initarg :created-at
               :initform (simple-date:universal-time-to-timestamp
                          (local-time:timestamp-to-universal
                           (local-time:now))))
   (item-id  :initarg :item
	  :accessor acquisition-item
	  :col-type integer)
   (inventory-id :initarg :inventory
		 :accessor acquisition-inventory
		 :col-type integer)
   (location-id :initarg :location
		:accessor acquisition-location
		:col-type integer)
   (price-paid :initarg :price
	       :accessor acquisition-price-paid
	       :col-type :money)
   (quantity-acquired :initarg :quantity
		      :accessor acquisition-quantity-acquired
		      :col-type (:real)))
  (:metaclass postmodern:dao-class)
  (:keys id))

(deftable acquisition
  (!dao-def)
  (!foreign 'item 'item-id 'id :on-delete :cascade :on-update :cascade)
  (!foreign 'location 'location-id 'id :on-delete :cascade :on-update :cascade)
  (!foreign 'inventory 'inventory-id 'id :on-delete :cascade :on-update :cascade))


;;; Database Functions
;;; ;;;;;;;;;;;;;;;;;;

(defmacro insert-new (table &rest keywords)
  `(mito:insert-dao (make-instance ,table ,@keywords)))

(defun insert-test-data ()
  (query (:insert-into 'location :set 'name "Mary's Corner Store" 'position "57e Ave." 'created_at (:now) ))
  (query (:insert-into 'user :set 'username "lemelino" 'created_at (:now) ))
  (query (:insert-into 'inventory :set 'name "Home" 'user-id 1 'created_at (:now)))
  (query (:insert-into 'item :set 'name "Farine Blanche" 'brand "La Milanaise" 'notes "Best flour. Buy all the time." 'measure-unit "kg" 'priority 10 'created_at (:now)))
  
  (query (:insert-into 'acquisition :set 'item-id 1 'location-id 1 'inventory-id 1 'price_paid 10.99 'quantity_acquired 10 'created_at (:now)))
  (query (:insert-into 'acquisition :set 'item-id 1 'location-id 1 'inventory-id 1 'price_paid 8.99 'quantity_acquired 14 'created_at (:now)))
  (query (:insert-into 'depletion :set 'quantity 5 'item-id 1 'inventory-id 1 'created_at (:now)))
  (query (:insert-into 'depletion :set 'quantity 7 'item-id 1 'inventory-id 1 'created_at (:now)))
  (format t "Insertion of test data completed!"))

(defun initialize-database ()
  (loop for x in '(location user item inventory depletion acquisition)
	do (create-table x))
  (insert-test-data))

(defun drop-database ()
  (loop for x in '(:depletion :acquisition :inventory :item :location :user)
	do (postmodern:execute (:drop-table :if-exists x))))

(defun reinitialize-database ()
  (drop-database)
  (initialize-database))

;;; Helper Functions
;;; ;;;;;;;;;;;;;;;;

(defmacro with-time-period (start-date end-date &body body)
  `(progn
    (unless ,start-date
      (setf ,start-date
	    "1900-01-01"))
    (unless ,end-date
      (setf ,end-date
	    (local-time:format-timestring nil (now) :format '(:year #\- :month #\- :day))))
    ,@body))

(defun sum-over-time-query (table amount-field item_id inventory_id since before)
  (with-time-period since before
    (query (:select (:sum amount-field)
	   :from table
	   :where (:and (:= 'item_id item_id)
			(:= 'inventory_id inventory_id)
			(:between 'created_at since before))
	   :group-by 'item_id 'inventory_id)
	   :single!)))



(defmethod quantity-consumed ((item item)
			      (inventory inventory)
			      &key (since nil) (before nil))
  (sum-over-time-query 'depletion
		       'depletion.quantity
		       (id item) (id inventory)
		       since before))

(defmethod quantity-acquired ((item item)
			      (inventory inventory)
			      &key (since nil) (before nil))
  (sum-over-time-query 'acquisition
		       'acquisition.quantity_acquired
		       (id item) (id inventory)
		       since before))

(defmethod remaining-quantity ((item item)
			       (inventory inventory)
			       &key (since nil) (before nil))
    (- (quantity-acquired item inventory :since since :before before)
       (quantity-consumed item inventory :since since :before before)))

(defmethod get-last-acquisition ((item item))
  (car (select-dao 'acquisition
	 (order-by (:desc :created_at))
	 (limit 1))))

(defun get-inventory (name)
  (let* ((inventory (car (select-dao 'inventory
			   (where (:like :name #?"%$(name)%")))))
	 (items (find-dao 'item
		  :distinct
		  (inner-join :acquisition :on (:= :item.id :acquisition.item_id))
		  (inner-join :inventory :on (:= :inventory.id :acquisition.inventory_id)))))
    (values inventory items)))


